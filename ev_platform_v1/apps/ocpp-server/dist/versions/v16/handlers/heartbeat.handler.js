"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleHeartbeat = handleHeartbeat;
async function handleHeartbeat(connection, payload) {
    return {
        currentTime: new Date().toISOString()
    };
}
//# sourceMappingURL=heartbeat.handler.js.map