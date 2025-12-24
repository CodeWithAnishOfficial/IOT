import { OCPPConnection } from '../../../core/connection.manager';
import { ChargingSession, Logger, RabbitMQService } from '@ev-platform-v1/shared';

const logger = new Logger('StopTransactionHandler');

export async function handleStopTransaction(connection: OCPPConnection, payload: any) {
  const { transactionId, meterStop, timestamp, idTag } = payload;
  logger.info(`StopTransaction from ${connection.id} transaction ${transactionId}`);

  let sessionData: any = null;

  const session = await ChargingSession.findOne({ transaction_id: transactionId });
  if (session) {
    session.stop_time = new Date(timestamp);
    session.meter_stop = meterStop;
    session.total_energy = meterStop - session.meter_start;
    session.status = 'completed';
    await session.save();
    sessionData = session.toObject();
  } else {
      // In case session is not found (maybe started offline?), create a partial one or just log
      logger.warn(`Session not found for transactionId ${transactionId}`);
  }

  // Publish CDR event to RabbitMQ
  try {
      const rabbit = RabbitMQService.getInstance();
      await rabbit.publish('cdr_events', {
          transactionId,
          chargerId: connection.id,
          meterStop,
          timestamp,
          totalEnergy: session ? session.total_energy : 0,
          userId: session ? session.user_id : null,
          sessionId: session ? session.session_id : null
      });
      logger.info(`Published CDR event for transaction ${transactionId}`);
  } catch (error) {
      logger.error('Failed to publish CDR event', error);
  }

  return {
    idTagInfo: {
      status: 'Accepted'
    }
  };
}
