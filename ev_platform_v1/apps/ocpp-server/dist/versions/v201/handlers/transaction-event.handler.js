"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleTransactionEvent = handleTransactionEvent;
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('TransactionEventHandlerV201');
async function handleTransactionEvent(connection, payload) {
    const { eventType, timestamp, triggerReason, seqNo, transactionInfo, meterValue, evse, idToken } = payload;
    const transactionId = transactionInfo.transactionId;
    logger.info(`V2.0.1 TransactionEvent ${eventType} from ${connection.id} tx ${transactionId}`);
    try {
        if (eventType === 'Started') {
            await handleStarted(connection, payload);
        }
        else if (eventType === 'Updated') {
            await handleUpdated(connection, payload);
        }
        else if (eventType === 'Ended') {
            await handleEnded(connection, payload);
        }
    }
    catch (error) {
        logger.error(`Error handling TransactionEvent ${eventType}`, error);
    }
    // Response usually includes idTokenInfo if idToken was present
    let response = {};
    if (idToken) {
        response.idTokenInfo = {
            status: 'Accepted'
        };
    }
    return response;
}
async function handleStarted(connection, payload) {
    const { transactionInfo, timestamp, evse, idToken, meterValue } = payload;
    // Create Session
    await shared_1.ChargingSession.create({
        session_id: Math.floor(1000000 + Math.random() * 9000000),
        transaction_id: transactionInfo.transactionId, // String in 2.0.1? Model says number...
        charger_id: connection.id,
        connector_id: evse ? evse.id : 1,
        user_id: idToken ? idToken.idToken : 'unknown',
        start_time: new Date(timestamp),
        start_meter_value: getMeterValue(meterValue),
        status: true,
        charger_status: 'Charging',
        auth_tag: idToken ? idToken.idToken : undefined
    });
}
async function handleUpdated(connection, payload) {
    // Usually updates meter values
    const { transactionInfo, meterValue } = payload;
    // We could update current meter reading in session if we tracked it
}
async function handleEnded(connection, payload) {
    const { transactionInfo, timestamp, meterValue, idToken } = payload;
    // transaction_id in model is Number, but 2.0.1 uses strings (UUIDs). 
    // This might be a schema conflict if we strictly enforce Number for transaction_id.
    // Assuming for now we cast or the model allows mixed (it was defined as Number in recent changes).
    // If transactionInfo.transactionId is a UUID, this find might fail if we don't handle it.
    // For now, let's assume we search by it as is.
    const session = await shared_1.ChargingSession.findOne({ transaction_id: transactionInfo.transactionId });
    let totalEnergy = 0;
    let meterStop = getMeterValue(meterValue);
    if (session) {
        session.stop_time = new Date(timestamp);
        session.meter_stop = meterStop;
        session.unit_consumed = meterStop - session.start_meter_value;
        session.status = false;
        session.charger_status = 'Completed';
        await session.save();
        totalEnergy = session.unit_consumed;
    }
    // Publish CDR
    try {
        const rabbit = shared_1.RabbitMQService.getInstance();
        await rabbit.publish('cdr_events', {
            transactionId: transactionInfo.transactionId,
            chargerId: connection.id,
            meterStop: meterStop,
            timestamp,
            totalEnergy: totalEnergy,
            userId: session ? session.user_id : (idToken ? idToken.idToken : null),
            sessionId: session ? session.session_id : null
        });
    }
    catch (error) {
        logger.error('Failed to publish CDR event', error);
    }
}
function getMeterValue(meterValue) {
    if (!meterValue || meterValue.length === 0)
        return 0;
    // Find the energy import register
    // Simplified logic: take first sampled value
    const sampledValue = meterValue[0].sampledValue;
    if (sampledValue && sampledValue.length > 0) {
        return parseFloat(sampledValue[0].value);
    }
    return 0;
}
//# sourceMappingURL=transaction-event.handler.js.map