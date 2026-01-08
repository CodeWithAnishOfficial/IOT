import { OCPPConnection } from '../../../core/connection.manager';
import { ChargingSession, Logger, RabbitMQService } from '@ev-platform-v1/shared';

const logger = new Logger('StopTransactionHandler');

export async function handleStopTransaction(connection: OCPPConnection, payload: any) {
  const { transactionId, meterStop, timestamp, idTag, reason } = payload;
  logger.info(`StopTransaction from ${connection.id} transaction ${transactionId}`);

  let sessionData: any = null;

  const session = await ChargingSession.findOne({ transaction_id: transactionId });
  if (session) {
    session.stop_time = new Date(timestamp);
    session.meter_stop = meterStop;
    // Calculate consumed
    session.unit_consumed = (meterStop - (session.start_meter_value || 0)); // Assuming Wh
    if (session.unit_consumed < 0) session.unit_consumed = 0;
    
    // Calculate Price (Mock logic or use Tariff)
    const unitPrice = 8.26; // From example
    session.unit_price = unitPrice;
    session.price = (session.unit_consumed / 1000) * unitPrice; // Assuming Wh -> kWh
    session.consumed_amount = session.price;
    
    session.charger_status = 'Completed';
    session.transactionState = 'Completed';
    session.stop_reason = reason || 'Local';
    session.stopPending = false;
    session.modified_date = new Date();
    
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
          totalEnergy: session ? session.unit_consumed : 0,
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
