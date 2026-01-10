"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleHeartbeat = handleHeartbeat;
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('HeartbeatHandlerV201');
async function handleHeartbeat(connection, payload) {
    logger.info(`V2.0.1 Heartbeat from ${connection.id}`);
    return {
        currentTime: new Date().toISOString()
    };
}
//# sourceMappingURL=heartbeat.handler.js.map