"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleHeartbeat = handleHeartbeat;
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('HeartbeatHandler');
async function handleHeartbeat(connection, payload) {
    try {
        // Update charger status to online and update last_seen
        await shared_1.Charger.updateOne({ charger_id: connection.id }, {
            $set: {
                status: 'online',
                last_seen: new Date()
            }
        });
        logger.info(`Received Heartbeat from ${connection.id}, status updated to online`);
    }
    catch (error) {
        logger.error(`Failed to update status for ${connection.id}`, error);
    }
    return {
        currentTime: new Date().toISOString()
    };
}
//# sourceMappingURL=heartbeat.handler.js.map