import { OCPPConnection } from '../../../core/connection.manager';
import { ChargingStation, Logger } from '@ev-platform-v1/shared';

const logger = new Logger('BootNotificationHandler');

export async function handleBootNotification(connection: OCPPConnection, payload: any) {
  logger.info(`BootNotification from ${connection.id}`, payload);
  logger.info(`ENV CHECK: HEARTBEAT_INTERVAL is "${process.env.HEARTBEAT_INTERVAL}"`);

  const { chargePointVendor, chargePointModel, chargePointSerialNumber, firmwareVersion } = payload;
  
  // Update station details
  await ChargingStation.updateOne(
    { charger_id: connection.id },
    { 
      $set: { 
        vendor: chargePointVendor,
        modelName: chargePointModel,
        serial_number: chargePointSerialNumber,
        firmware_version: firmwareVersion,
        updated_at: new Date()
      }
    }
  );

  return {
    status: 'Accepted',
    currentTime: new Date().toISOString(),
    interval: parseInt(process.env.HEARTBEAT_INTERVAL || '60') // Get from env or default to 60
  };
}
