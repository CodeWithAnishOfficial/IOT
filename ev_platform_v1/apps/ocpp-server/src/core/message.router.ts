import { OCPPConnection } from './connection.manager';
import { Logger } from '@ev-platform-v1/shared';
import { RouterV16 } from '../versions/v16/router';
import { RouterV201 } from '../versions/v201/router';

const logger = new Logger('MessageRouter');

export class MessageRouter {
  static async handleMessage(connection: OCPPConnection, message: any) {
    if (!Array.isArray(message)) {
      logger.error(`Invalid message format from ${connection.id}: Not an array`);
      // Cannot send error because we don't have requestId
      return;
    }

    if (message.length < 3) {
       logger.error(`Invalid message format from ${connection.id}: Length ${message.length}`);
       return;
    }

    const [messageType, requestId, action, payload] = message;

    if (typeof messageType !== 'number') {
         logger.error(`Invalid MessageType from ${connection.id}`);
         return;
    }

    if (typeof requestId !== 'string') {
         logger.error(`Invalid RequestId from ${connection.id}`);
         return;
    }

    if (messageType !== 2) {
      // We currently only handle requests (Type 2) from Charge Points
      // Type 3 (Response) and 4 (Error) are handled by callbacks if we sent a request (not implemented in this simplified router yet)
      if (messageType === 3) {
          logger.info(`Received Response for Request ${requestId} from ${connection.id}`);
          // TODO: Match with pending requests
      } else if (messageType === 4) {
          logger.warn(`Received Error for Request ${requestId} from ${connection.id}`);
      }
      return;
    }
    
    // Validate Action
    if (typeof action !== 'string') {
        logger.error(`Invalid Action from ${connection.id}`);
        connection.sendError(requestId, 'ProtocolError', 'Action must be a string');
        return;
    }

    // Delegate to version-specific router
    if (connection.version === '1.6') {
      await RouterV16.handleRequest(connection, action, payload, requestId);
    } else if (connection.version === '2.0.1' || connection.version === '2.0') {
      await RouterV201.handleRequest(connection, action, payload, requestId);
    } else {
      logger.warn(`Unsupported version ${connection.version} for ${connection.id}`);
      connection.sendError(requestId, 'NotSupported', `Version ${connection.version} not supported`);
    }
  }
}

