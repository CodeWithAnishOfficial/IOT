import { OCPPConnection } from './connection.manager';
import { Logger } from '@ev-platform-v1/shared';
import { RouterV16 } from '../versions/v16/router';
import { RouterV201 } from '../versions/v201/router';

const logger = new Logger('MessageRouter');

export class MessageRouter {
  static async handleMessage(connection: OCPPConnection, message: any) {
    if (!Array.isArray(message)) {
      logger.error(`Invalid message format from ${connection.id}`);
      return;
    }

    const [messageType, requestId, action, payload] = message;

    if (messageType !== 2) {
      // We currently only handle requests (Type 2) from Charge Points
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

