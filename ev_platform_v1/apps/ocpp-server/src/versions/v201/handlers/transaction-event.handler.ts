import { OCPPConnection } from '../../../core/connection.manager';
import { ChargingSession, Logger, RabbitMQService } from '@ev-platform-v1/shared';
import { v4 as uuidv4 } from 'uuid';

const logger = new Logger('TransactionEventHandlerV201');

export async function handleTransactionEvent(connection: OCPPConnection, payload: any) {
  const { eventType, timestamp, triggerReason, seqNo, transactionInfo, meterValue, evse, idToken } = payload;
  const transactionId = transactionInfo.transactionId;
  
  logger.info(`V2.0.1 TransactionEvent ${eventType} from ${connection.id} tx ${transactionId}`);

  try {
      if (eventType === 'Started') {
          await handleStarted(connection, payload);
      } else if (eventType === 'Updated') {
          await handleUpdated(connection, payload);
      } else if (eventType === 'Ended') {
          await handleEnded(connection, payload);
      }
  } catch (error) {
      logger.error(`Error handling TransactionEvent ${eventType}`, error);
  }

  // Response usually includes idTokenInfo if idToken was present
  let response: any = {};
  if (idToken) {
      response.idTokenInfo = {
          status: 'Accepted'
      };
  }
  return response;
}

async function handleStarted(connection: OCPPConnection, payload: any) {
    const { transactionInfo, timestamp, evse, idToken, meterValue } = payload;
    
    // Create Session
    await ChargingSession.create({
        session_id: uuidv4(),
        transaction_id: transactionInfo.transactionId, // String in 2.0.1
        charger_id: connection.id,
        connector_id: evse ? evse.id : 1,
        user_id: idToken ? idToken.idToken : 'unknown',
        start_time: new Date(timestamp),
        meter_start: getMeterValue(meterValue),
        status: 'active',
        auth_tag: idToken ? idToken.idToken : undefined
    });
}

async function handleUpdated(connection: OCPPConnection, payload: any) {
    // Usually updates meter values
    const { transactionInfo, meterValue } = payload;
    // We could update current meter reading in session if we tracked it
}

async function handleEnded(connection: OCPPConnection, payload: any) {
    const { transactionInfo, timestamp, meterValue, idToken } = payload;
    
    const session = await ChargingSession.findOne({ transaction_id: transactionInfo.transactionId });
    let totalEnergy = 0;
    let meterStop = getMeterValue(meterValue);

    if (session) {
        session.stop_time = new Date(timestamp);
        session.meter_stop = meterStop;
        session.total_energy = meterStop - session.meter_start;
        session.status = 'completed';
        await session.save();
        totalEnergy = session.total_energy;
    }

    // Publish CDR
    try {
        const rabbit = RabbitMQService.getInstance();
        await rabbit.publish('cdr_events', {
            transactionId: transactionInfo.transactionId,
            chargerId: connection.id,
            meterStop: meterStop,
            timestamp,
            totalEnergy: totalEnergy,
            userId: session ? session.user_id : (idToken ? idToken.idToken : null),
            sessionId: session ? session.session_id : null
        });
    } catch (error) {
        logger.error('Failed to publish CDR event', error);
    }
}

function getMeterValue(meterValue: any[]): number {
    if (!meterValue || meterValue.length === 0) return 0;
    // Find the energy import register
    // Simplified logic: take first sampled value
    const sampledValue = meterValue[0].sampledValue;
    if (sampledValue && sampledValue.length > 0) {
        return parseFloat(sampledValue[0].value);
    }
    return 0;
}
