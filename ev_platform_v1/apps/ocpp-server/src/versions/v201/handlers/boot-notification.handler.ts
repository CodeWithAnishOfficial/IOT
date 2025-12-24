import { OCPPConnection } from '../../../core/connection.manager';
import { Logger } from '@ev-platform-v1/shared';

const logger = new Logger('BootNotificationHandlerV201');

export async function handleBootNotification(connection: OCPPConnection, payload: any) {
  const { reason, chargingStation } = payload;
  logger.info(`V2.0.1 BootNotification from ${connection.id}: ${reason}`, chargingStation);

  // In a real system, we would validate against a database of allowed chargers
  // and possibly firmware versions.

  return {
    currentTime: new Date().toISOString(),
    interval: 300, // 5 minutes heartbeat interval
    status: 'Accepted'
  };
}
