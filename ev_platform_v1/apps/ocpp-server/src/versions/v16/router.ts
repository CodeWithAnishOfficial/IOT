import { OCPPConnection } from '../../core/connection.manager';
import { Logger } from '@ev-platform-v1/shared';
import * as Handlers from './handlers';

const logger = new Logger('RouterV16');

export class RouterV16 {
  static async handleRequest(connection: OCPPConnection, action: string, payload: any, requestId: string) {
    logger.info(`V1.6: Received ${action} from ${connection.id}`);

    try {
      let responsePayload = {};
      
      switch (action) {
        case 'BootNotification':
          responsePayload = await Handlers.handleBootNotification(connection, payload);
          break;
        case 'Heartbeat':
          responsePayload = await Handlers.handleHeartbeat(connection, payload);
          break;
        case 'StatusNotification':
          responsePayload = await Handlers.handleStatusNotification(connection, payload);
          break;
        case 'Authorize':
          responsePayload = await Handlers.handleAuthorize(connection, payload);
          break;
        case 'StartTransaction':
          responsePayload = await Handlers.handleStartTransaction(connection, payload);
          break;
        case 'StopTransaction':
          responsePayload = await Handlers.handleStopTransaction(connection, payload);
          break;
        case 'MeterValues':
          responsePayload = await Handlers.handleMeterValues(connection, payload);
          break;
        default:
          logger.warn(`Unknown action: ${action} from ${connection.id}`);
          connection.sendError(requestId, 'NotImplemented', `Action ${action} not implemented`);
          return;
      }

      connection.sendResponse(requestId, responsePayload);

    } catch (error: any) {
      logger.error(`Error handling ${action} from ${connection.id}`, error);
      connection.sendError(requestId, 'InternalError', error.message);
    }
  }
}
