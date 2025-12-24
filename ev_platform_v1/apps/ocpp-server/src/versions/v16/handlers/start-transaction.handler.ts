import { OCPPConnection } from '../../../core/connection.manager';
import { ChargingSession, Logger } from '@ev-platform-v1/shared';
import { v4 as uuidv4 } from 'uuid';
import { SmartChargingService } from '../../../services/smart-charging.service';

const logger = new Logger('StartTransactionHandler');

export async function handleStartTransaction(connection: OCPPConnection, payload: any) {
  const { connectorId, idTag, meterStart, timestamp } = payload;
  logger.info(`StartTransaction from ${connection.id} connector ${connectorId}`);

  const transactionId = Math.floor(Date.now() / 1000);
  const sessionId = uuidv4();

  // Create active session
  await ChargingSession.create({
    session_id: sessionId,
    transaction_id: transactionId,
    charger_id: connection.id,
    connector_id: connectorId,
    user_id: idTag, // Using tag as user_id reference for now
    start_time: new Date(timestamp),
    meter_start: meterStart,
    status: 'active',
    auth_tag: idTag
  });

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
