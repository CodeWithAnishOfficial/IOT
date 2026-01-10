"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleStopTransaction = handleStopTransaction;
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('StopTransactionHandler');
async function handleStopTransaction(connection, payload) {
    const { transactionId, meterStop, timestamp, idTag, reason } = payload;
    logger.info(`StopTransaction from ${connection.id} transaction ${transactionId}`);
    let sessionData = null;
    const session = await shared_1.ChargingSession.findOne({ transaction_id: transactionId });
    if (session) {
        session.stop_time = new Date(timestamp);
        session.meter_stop = meterStop;
        // Calculate consumed
        session.unit_consumed = (meterStop - (session.start_meter_value || 0)); // Assuming Wh
        if (session.unit_consumed < 0)
            session.unit_consumed = 0;
        // Calculate Price (Mock logic or use Tariff)
        const unitPrice = 8.26; // From example
        session.unit_price = unitPrice;
        session.price = (session.unit_consumed / 1000) * unitPrice; // Assuming Wh -> kWh
        session.consumed_amount = session.price;
        session.charger_status = 'Completed';
        session.transactionState = 'Completed';
        session.stop_reason = reason || 'Local';
        session.stopPending = false;
        session.modified_date = new Date();
        await session.save();
        // Clear Lock
        try {
            const redis = shared_1.RedisService.getInstance();
            const lockKey = `lock:${session.charger_id}:${session.connector_id}`;
            await redis.del(lockKey);
            logger.info(`Released lock for ${lockKey}`);
        }
        catch (e) {
            logger.error('Failed to release lock', e);
        }
        sessionData = session.toObject();
    }
    else {
        // In case session is not found (maybe started offline?), create a partial one or just log
        logger.warn(`Session not found for transactionId ${transactionId}`);
    }
    // Publish CDR event to RabbitMQ
    try {
        const rabbit = shared_1.RabbitMQService.getInstance();
        await rabbit.publish('cdr_events', {
            transactionId,
            chargerId: connection.id,
            meterStop,
            timestamp,
            totalEnergy: session ? (session.unit_consumed / 1000) : 0,
            userId: session ? session.user_id : null,
            userEmail: session ? session.email_id : null,
            sessionId: session ? session.session_id : null
        });
        logger.info(`Published CDR event for transaction ${transactionId}`);
    }
    catch (error) {
        logger.error('Failed to publish CDR event', error);
    }
    return {
        idTagInfo: {
            status: 'Accepted'
        }
    };
}
//# sourceMappingURL=stop-transaction.handler.js.map