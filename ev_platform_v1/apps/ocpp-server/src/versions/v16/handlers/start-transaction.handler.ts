import { OCPPConnection } from '../../../core/connection.manager';
import { ChargingSession, Logger, RabbitMQService, User } from '@ev-platform-v1/shared';
import { SmartChargingService } from '../../../services/smart-charging.service';

const logger = new Logger('StartTransactionHandler');

export async function handleStartTransaction(connection: OCPPConnection, payload: any) {
  const { connectorId, idTag, meterStart, timestamp } = payload;
  logger.info(`StartTransaction from ${connection.id} connector ${connectorId}`);

  const transactionId = Math.floor(Date.now() / 1000); // 1.6 uses Integer
  let sessionId = 0; // Will be assigned
  let userId = idTag; // Default to idTag if no pending session found

  // Try to find pending session from RemoteStartTransaction
  // We match charger, connector, and status.
  const pendingSession = await ChargingSession.findOne({
      charger_id: connection.id,
      connector_id: connectorId,
      // Status might be true/false or 'Pending' depending on how we saved it.
      // In ChargingService we saved: status: true, charger_status: 'Pending'
      charger_status: 'Pending'
  }).sort({ created_date: -1 });

  if (pendingSession) {
      logger.info(`Found pending session ${pendingSession.session_id} for transaction`);
      pendingSession.transaction_id = transactionId; // Link OCPP transaction ID
      pendingSession.charger_status = 'Charging';
      pendingSession.start_time = new Date(timestamp);
      pendingSession.start_meter_value = meterStart;
      pendingSession.current_meter_value = meterStart;
      pendingSession.auth_tag = idTag; 
      pendingSession.transactionState = 'Started';
      pendingSession.wsActive = true;
      pendingSession.lastWsPing = new Date();
      await pendingSession.save();
      
      sessionId = pendingSession.session_id;
      // userId = pendingSession.user_id; // Keep as is
  } else {
      logger.info(`No pending session found. Validating idTag ${idTag}...`);
      
      // Validate User (RFID or Email)
      const user = await User.findOne({
          $or: [
              { rfid_tag: idTag },
              { email_id: idTag }
          ]
      });

      if (!user) {
          logger.warn(`Unauthorized StartTransaction attempt with tag ${idTag}`);
          return {
              transactionId,
              idTagInfo: {
                  status: 'Invalid'
              }
          };
      }

      logger.info(`Authorized user ${user.email_id} for ad-hoc session`);

      // Create active session
      // Generate numeric ID
      sessionId = Math.floor(1000000 + Math.random() * 9000000);
      
      await ChargingSession.create({
        session_id: sessionId,
        transaction_id: transactionId,
        charger_id: connection.id,
        connector_id: connectorId,
        user_id: user.user_id, 
        email_id: user.email_id,
        start_time: new Date(timestamp),
        start_meter_value: meterStart,
        current_meter_value: meterStart,
        status: true,
        charger_status: 'Charging',
        auth_tag: idTag,
        transactionState: 'Started',
        wsActive: true,
        lastWsPing: new Date(),
        created_date: new Date(),
        modified_date: new Date()
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
