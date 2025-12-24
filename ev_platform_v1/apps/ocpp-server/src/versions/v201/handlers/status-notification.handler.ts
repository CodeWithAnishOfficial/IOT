import { OCPPConnection } from '../../../core/connection.manager';
import { ChargingStation, Logger } from '@ev-platform-v1/shared';

const logger = new Logger('StatusNotificationHandlerV201');

export async function handleStatusNotification(connection: OCPPConnection, payload: any) {
  const { timestamp, connectorStatus, evseId, connectorId } = payload;
  logger.info(`V2.0.1 StatusNotification from ${connection.id}: EVSE ${evseId} Connector ${connectorId} -> ${connectorStatus}`);

  // Update DB
  // Note: OCPP 2.0.1 uses EVSE ID and Connector ID.
  // Our schema currently has a simple array of connectors. 
  // We might map EVSE ID to our connector_id for simplicity or just log it.
  
  // Mapping approach: If evseId > 0, we treat it as connector_id.
  const targetConnectorId = evseId > 0 ? evseId : connectorId;

  if (targetConnectorId > 0) {
      await ChargingStation.findOneAndUpdate(
        { charger_id: connection.id, 'connectors.connector_id': targetConnectorId },
        { 
            $set: { 
                'connectors.$.status': connectorStatus,
                updated_at: new Date()
            },
            status: 'online' // Update station status as well
        }
      );
  }

  return {}; // Empty response
}
