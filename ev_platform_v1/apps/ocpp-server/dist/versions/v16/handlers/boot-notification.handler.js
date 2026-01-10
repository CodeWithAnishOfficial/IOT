"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleBootNotification = handleBootNotification;
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('BootNotificationHandler');
async function handleBootNotification(connection, payload) {
    logger.info(`BootNotification from ${connection.id}`, payload);
    logger.info(`ENV CHECK: HEARTBEAT_INTERVAL is "${process.env.HEARTBEAT_INTERVAL}"`);
    const { chargePointVendor, chargePointModel, chargePointSerialNumber, firmwareVersion } = payload;
    // Update station details
    await shared_1.Charger.updateOne({ charger_id: connection.id }, {
        $set: {
            vendor: chargePointVendor,
            modelName: chargePointModel,
            serial_number: chargePointSerialNumber,
            firmware_version: firmwareVersion,
            updated_at: new Date()
        }
    });
    return {
        status: 'Accepted',
        currentTime: new Date().toISOString(),
        interval: parseInt(process.env.HEARTBEAT_INTERVAL || '60') // Get from env or default to 60
    };
}
//# sourceMappingURL=boot-notification.handler.js.map