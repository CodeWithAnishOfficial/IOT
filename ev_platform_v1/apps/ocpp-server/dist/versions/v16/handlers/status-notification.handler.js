"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleStatusNotification = handleStatusNotification;
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('StatusNotificationHandler');
async function handleStatusNotification(connection, payload) {
    const { connectorId, status, errorCode } = payload;
    logger.info(`StatusNotification from ${connection.id}: Connector ${connectorId} -> ${status}`);
    await shared_1.Charger.updateOne({ charger_id: connection.id, 'connectors.connector_id': connectorId }, {
        $set: {
            'connectors.$.status': status,
            updated_at: new Date()
        }
    });
    // If connector doesn't exist, push it (simplified logic, ideally check existence first)
    // For now assuming connectors are pre-provisioned or we upsert carefully.
    // Actually, let's just update the main status if it's connector 0 (Main controller)
    if (connectorId === 0) {
        await shared_1.Charger.updateOne({ charger_id: connection.id }, { status: status === 'Available' ? 'online' : status.toLowerCase() });
    }
    // Publish Event
    try {
        const rabbit = shared_1.RabbitMQService.getInstance();
        await rabbit.publish('station_status_events', {
            chargerId: connection.id,
            connectorId,
            status,
            errorCode,
            timestamp: new Date()
        });
    }
    catch (error) {
        logger.error('Failed to publish station_status_events', error);
    }
    return {};
}
//# sourceMappingURL=status-notification.handler.js.map