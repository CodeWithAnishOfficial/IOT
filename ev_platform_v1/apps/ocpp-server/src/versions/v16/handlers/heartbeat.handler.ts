import { OCPPConnection } from '../../../core/connection.manager';

export async function handleHeartbeat(connection: OCPPConnection, payload: any) {
  return {
    currentTime: new Date().toISOString()
  };
}
