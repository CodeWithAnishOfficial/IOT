"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleBootNotification = handleBootNotification;
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('BootNotificationHandlerV201');
async function handleBootNotification(connection, payload) {
    const { reason, chargingStation } = payload;
    logger.info(`V2.0.1 BootNotification from ${connection.id}: ${reason}`, chargingStation);
    // In a real system, we would validate against a database of allowed chargers
    // and possibly firmware versions.
    return {
        currentTime: new Date().toISOString(),
        interval: parseInt(process.env.HEARTBEAT_INTERVAL || '60'), // Get from env or default to 60
        status: 'Accepted'
    };
}
//# sourceMappingURL=boot-notification.handler.js.map