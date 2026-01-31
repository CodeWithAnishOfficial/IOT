"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChargingService = void 0;
const shared_1 = require("@ev-platform-v1/shared");
const payment_service_1 = require("./payment.service");
const logger = new shared_1.Logger('ChargingService');
const redis = shared_1.RedisService.getInstance();
const paymentService = new payment_service_1.PaymentService();
class ChargingService {
    static async startSession(userId, stationId, connectorId, amount, paymentDetails) {
        try {
            // 1. Validate User
            const user = await shared_1.User.findOne({ email_id: userId });
            if (!user) {
                throw new Error('User not found');
            }
            // 1b. Verify Lock
            const lockKey = `lock:${stationId}:${connectorId}`;
            const existingLock = await redis.get(lockKey);
            if (existingLock && existingLock !== userId) {
                throw new Error('Connector is reserved by another user');
            }
            // 2. Validate Payment OR Balance
            let isDirectPayment = false;
            if (paymentDetails) {
                // Verify Razorpay Payment
                const isValid = await paymentService.verifyPayment(paymentDetails.orderId, paymentDetails.paymentId, paymentDetails.signature);
                if (!isValid) {
                    throw new Error('Invalid payment signature');
                }
                isDirectPayment = true;
                logger.info(`Direct payment verified for user ${userId}: ${paymentDetails.paymentId}`);
                // Save Payment Details to DB as per requirement
                const paymentId = Math.floor(10000 + Math.random() * 90000);
                logger.info(`Creating Payment record: ${paymentId}`);
                await shared_1.Payment.create({
                    payment_id: paymentId,
                    user_id: user.user_id,
                    username: user.username || 'Unknown',
                    phone_number: user.phone_no || 'Unknown',
                    email_id: user.email_id,
                    recharge_amount: amount,
                    transaction_id: paymentDetails.paymentId,
                    response: 'SUCCESS',
                    recharged_date: new Date(),
                    recharged_by: user.email_id,
                    payment_method: 'UPI', // Assuming UPI as per example, or we could pass it
                    status: true
                });
                logger.info(`Payment record created`);
            }
            else {
                // Fallback to Wallet Check
                if (user.wallet_bal < amount) {
                    throw new Error('Insufficient wallet balance');
                }
            }
            // 3. Validate Station
            const station = await shared_1.Charger.findOne({ charger_id: stationId });
            if (!station) {
                throw new Error('Station not found');
            }
            if (station.status === 'offline') {
                throw new Error('Station is offline');
            }
            // 3. Create Session Record (Pending)
            // Generate 7-digit Session ID
            const sessionId = Math.floor(1000000 + Math.random() * 9000000);
            logger.info(`Creating ChargingSession: ${sessionId} for user ${user.user_id}`);
            const session = await shared_1.ChargingSession.create({
                session_id: sessionId,
                user_id: user.user_id, // Use numeric ID
                email_id: user.email_id,
                charger_id: stationId,
                connector_id: Number(connectorId),
                status: true, // Boolean true as per requirement (or pending?) User example showed true. 
                // But pending sessions shouldn't be "true" immediately? 
                // Wait, example showed "status": true for a COMPLETED session.
                // I'll set default true (active/valid record) but use 'charger_status' for state.
                charger_status: 'Pending',
                start_time: new Date(),
                start_meter_value: 0,
                unit_consumed: 0,
                consumed_amount: 0,
                price: 0,
                unit_price: 0, // Should fetch from tariff?
                created_date: new Date(),
                modified_date: new Date(),
                stopPending: false,
                wsActive: false
            });
            logger.info(`ChargingSession created`);
            // 4. Publish Command to OCPP Server via Redis
            // The OCPP Server listens to 'ocpp:commands' and sends RemoteStartTransaction to charger
            const commandPayload = {
                chargerId: stationId,
                command: 'RemoteStartTransaction',
                payload: {
                    connectorId: Number(connectorId),
                    idTag: userId.substring(0, 20), // Truncate if needed, usually RFID or User ID
                    // Pass sessionId so OCPP Server can link it back? 
                    // RemoteStartTransaction payload (OCPP 1.6) doesn't strictly have sessionId field standard, 
                    // but we can assume idTag helps.
                }
            };
            await redis.publish('ocpp:commands', commandPayload);
            logger.info(`Published RemoteStartTransaction for ${stationId}:${connectorId} by ${userId} (Session: ${sessionId})`);
            // 5. Deduct Balance (Only if NOT direct payment)
            if (!isDirectPayment) {
                user.wallet_bal -= amount;
                await user.save();
            }
            return {
                sessionId,
                status: 'initiated',
                message: 'Charging command sent to station'
            };
        }
        catch (error) {
            logger.error('Error starting session', error.message);
            if (error.stack)
                logger.error(error.stack);
            throw error;
        }
    }
    static async stopSession(userEmail, sessionId) {
        try {
            const session = await shared_1.ChargingSession.findOne({ session_id: Number(sessionId) });
            if (!session) {
                throw new Error('Session not found');
            }
            if (session.email_id !== userEmail) {
                throw new Error('Unauthorized');
            }
            if (['completed', 'failed', 'stopped'].includes(session.charger_status)) {
                throw new Error('Session already ended');
            }
            // Publish RemoteStopTransaction
            const commandPayload = {
                chargerId: session.charger_id,
                command: 'RemoteStopTransaction',
                payload: {
                    transactionId: session.transaction_id || 0
                }
            };
            await redis.publish('ocpp:commands', commandPayload);
            logger.info(`Published RemoteStopTransaction for session ${sessionId}`);
            session.charger_status = 'stopping';
            await session.save();
            return {
                status: 'stopping',
                message: 'Stop command sent'
            };
        }
        catch (error) {
            logger.error('Error stopping session', error);
            throw error;
        }
    }
    static async checkConnectorStatus(stationId, connectorId, userId) {
        const station = await shared_1.Charger.findOne({ charger_id: stationId });
        if (!station) {
            throw new Error('Station not found');
        }
        if (station.status === 'offline') {
            throw new Error('Station is offline');
        }
        if (station.status === 'faulted') {
            throw new Error('Station is faulted');
        }
        const connector = station.connectors.find(c => c.connector_id === Number(connectorId));
        if (!connector) {
            throw new Error('Connector not found');
        }
        if (connector.status !== 'Available') {
            throw new Error(`Connector is ${connector.status}`);
        }
        // Check for Lock
        const lockKey = `lock:${stationId}:${connectorId}`;
        const existingLock = await redis.get(lockKey);
        if (existingLock && existingLock !== userId) {
            throw new Error('Connector is currently being accessed by another user');
        }
        // Set Lock (TTL 5 minutes)
        await redis.set(lockKey, userId, 300);
        // Trigger DataTransfer "Preparing" as requested
        // This sends [2, requestId, "DataTransfer", payload] to charger via OCPP Server
        const commandPayload = {
            chargerId: stationId,
            command: 'DataTransfer',
            payload: {
                vendorId: 'Outdid',
                messageId: 'TEST',
                data: 'Preparing',
                connectorId: Number(connectorId)
            }
        };
        await redis.publish('ocpp:commands', commandPayload);
        logger.info(`Triggered DataTransfer 'Preparing' for ${stationId}:${connectorId}`);
        return {
            allowed: true,
            status: connector.status,
            lock: 'acquired'
        };
    }
    static async releaseLock(stationId, connectorId, userId) {
        const lockKey = `lock:${stationId}:${connectorId}`;
        const existingLock = await redis.get(lockKey);
        if (existingLock === userId) {
            await redis.del(lockKey);
            return { released: true };
        }
        return { released: false, reason: 'Lock not held by user' };
    }
    static async getActiveSession(userId) {
        const session = await shared_1.ChargingSession.findOne({
            email_id: userId,
            charger_status: { $nin: ['completed', 'failed', 'stopped', 'Completed', 'Failed', 'Stopped'] } // Case insensitive safety or include both cases
        }).sort({ created_date: -1 });
        if (session) {
            // Fetch Charger Details
            const charger = await shared_1.Charger.findOne({ charger_id: session.charger_id });
            if (charger) {
                const connector = charger.connectors.find(c => c.connector_id === session.connector_id);
                return {
                    ...session.toObject(),
                    chargerDetails: {
                        charger_id: charger.charger_id,
                        max_power_kw: connector ? connector.max_power_kw : charger.max_power_kw,
                        connector_type: connector ? connector.type : 'Unknown',
                        name: charger.name,
                        address: charger.location?.address
                    }
                };
            }
        }
        return session;
    }
    static async getHistory(userId) {
        // Find all sessions for this user, sorted by date desc
        const sessions = await shared_1.ChargingSession.find({ email_id: userId })
            .sort({ created_date: -1 });
        return sessions;
    }
    static async getSessionDetails(userId, sessionId) {
        const session = await shared_1.ChargingSession.findOne({
            session_id: Number(sessionId),
            email_id: userId
        });
        if (!session)
            throw new Error('Session not found');
        return session;
    }
}
exports.ChargingService = ChargingService;
//# sourceMappingURL=charging.service.js.map