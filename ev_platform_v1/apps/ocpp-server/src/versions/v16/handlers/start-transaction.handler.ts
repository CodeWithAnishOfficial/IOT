import { OCPPConnection } from '../../../core/connection.manager';
import { ChargingSession, Logger, RabbitMQService } from '@ev-platform-v1/shared';
import { v4 as uuidv4 } from 'uuid';
import { SmartChargingService } from '../../../services/smart-charging.service';

const logger = new Logger('StartTransactionHandler');

export async function handleStartTransaction(connection: OCPPConnection, payload: any) {
  const { connectorId, idTag, meterStart, timestamp } = payload;
  logger.info(`StartTransaction from ${connection.id} connector ${connectorId}`);

  const transactionId = Math.floor(Date.now() / 1000); // 1.6 uses Integer
  let sessionId = uuidv4();
  let userId = idTag; // Default to idTag if no pending session found

  // Try to find pending session from RemoteStartTransaction
  // We match charger, connector, and status.
  const pendingSession = await ChargingSession.findOne({
      charger_id: connection.id,
      connector_id: connectorId,
      status: 'pending'
  }).sort({ created_at: -1 });

  if (pendingSession) {
      logger.info(`Found pending session ${pendingSession.session_id} for transaction`);
      pendingSession.transaction_id = transactionId; // Link OCPP transaction ID
      pendingSession.status = 'active';
      pendingSession.start_time = new Date(timestamp);
      pendingSession.meter_start = meterStart;
      pendingSession.auth_tag = idTag; // Update tag just in case
      await pendingSession.save();
      
      sessionId = pendingSession.session_id;
      userId = pendingSession.user_id;
  } else {
      logger.info(`No pending session found. Creating new ad-hoc session.`);
      // Create active session
      await ChargingSession.create({
        session_id: sessionId,
        transaction_id: transactionId,
        charger_id: connection.id,
        connector_id: connectorId,
        user_id: idTag, 
        start_time: new Date(timestamp),
        meter_start: meterStart,
        status: 'active',
        auth_tag: idTag
      });
  }

  // Publish Session Started Event
  try {
      const rabbit = RabbitMQService.getInstance();
      await rabbit.publish('session_started', {
          sessionId,
          userId,
          chargerId: connection.id,
          transactionId,
          status: 'active',
          timestamp
      });
  } catch (err) {
      logger.error('Failed to publish session_started', err);
  }

  // Trigger Smart Charging (Load Balancing) asynchronously
  SmartChargingService.applyLoadBalancing(connection, connectorId).catch(err => {
      logger.error('Failed to apply smart charging', err);
  });

  return {
    transactionId,
    idTagInfo: {
      status: 'Accepted'
    }
  };
}
