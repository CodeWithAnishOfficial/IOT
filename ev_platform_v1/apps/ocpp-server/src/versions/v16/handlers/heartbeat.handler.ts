import { OCPPConnection } from '../../../core/connection.manager';
import { Charger, Logger } from '@ev-platform-v1/shared';

const logger = new Logger('HeartbeatHandler');

export async function handleHeartbeat(connection: OCPPConnection, payload: any) {
  try {
    // Update charger status to online and update last_seen
    await Charger.updateOne(
        { charger_id: connection.id },
        { 
            $set: { 
                status: 'online',
                last_seen: new Date()
            } 
        }
    );
    logger.info(`Received Heartbeat from ${connection.id}, status updated to online`);
  } catch (error) {
    logger.error(`Failed to update status for ${connection.id}`, error);
  }

  return {
    currentTime: new Date().toISOString()
  };
}
