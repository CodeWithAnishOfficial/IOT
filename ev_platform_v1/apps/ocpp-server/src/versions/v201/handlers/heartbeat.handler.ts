import { OCPPConnection } from '../../../core/connection.manager';
import { Logger } from '@ev-platform-v1/shared';

const logger = new Logger('HeartbeatHandlerV201');

export async function handleHeartbeat(connection: OCPPConnection, payload: any) {
  logger.info(`V2.0.1 Heartbeat from ${connection.id}`);

  return {
    currentTime: new Date().toISOString()
  };
}
