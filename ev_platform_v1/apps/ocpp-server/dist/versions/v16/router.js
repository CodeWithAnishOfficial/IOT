"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.RouterV16 = void 0;
const shared_1 = require("@ev-platform-v1/shared");
const Handlers = __importStar(require("./handlers"));
const logger = new shared_1.Logger('RouterV16');
class RouterV16 {
    static async handleRequest(connection, action, payload, requestId) {
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
        }
        catch (error) {
            logger.error(`Error handling ${action} from ${connection.id}`, error);
            connection.sendError(requestId, 'InternalError', error.message);
        }
    }
}
exports.RouterV16 = RouterV16;
//# sourceMappingURL=router.js.map