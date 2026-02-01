import { Logger, User, ChargingSession, RedisService, Charger, Payment } from '@ev-platform-v1/shared';
import { PaymentService } from './payment.service';

const logger = new Logger('ChargingService');
const redis = RedisService.getInstance();
const paymentService = new PaymentService();

export class ChargingService {

  static async startSession(
    userId: string, 
    stationId: string, 
    connectorId: string | number, 
    amount: number,
    paymentDetails?: { orderId: string, paymentId: string, signature: string }
  ) {
    logger.info(`[StartSession] Request for User: ${userId}, Station: ${stationId}, Connector: ${connectorId}`);
    try {
      // 1. Validate User
      const user = await User.findOne({ email_id: userId });
      if (!user) {
        logger.error(`[StartSession] User not found: ${userId}`);
        throw new Error('User not found');
      }
      logger.info(`[StartSession] User found: ${user.user_id}`);

      // 1b. Verify Lock
      const lockKey = `lock:${stationId}:${connectorId}`;
      const existingLock = await redis.get(lockKey);
      if (existingLock && existingLock !== userId) {
           logger.warn(`[StartSession] Connector ${stationId}:${connectorId} is reserved by ${existingLock}, not ${userId}`);
           throw new Error('Connector is reserved by another user');
      }
      logger.info(`[StartSession] Lock verified (Held by user or free)`);

      // 2. Validate Payment OR Balance
      let isDirectPayment = false;
      
      if (paymentDetails) {
        logger.info(`[StartSession] Verifying payment: ${paymentDetails.paymentId}`);
        // Verify Razorpay Payment
        const isValid = await paymentService.verifyPayment(
          paymentDetails.orderId,
          paymentDetails.paymentId,
          paymentDetails.signature
        );
        
        if (!isValid) {
          logger.error(`[StartSession] Invalid payment signature`);
          throw new Error('Invalid payment signature');
        }
        
        isDirectPayment = true;
        logger.info(`Direct payment verified for user ${userId}: ${paymentDetails.paymentId}`);
        
        // Save Payment Details to DB as per requirement
        const paymentId = Math.floor(10000 + Math.random() * 90000);
        logger.info(`Creating Payment record: ${paymentId}`);
        await Payment.create({
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

      } else {
        // Fallback to Wallet Check
        if (user.wallet_bal < amount) {
          logger.error(`[StartSession] Insufficient wallet balance: ${user.wallet_bal} < ${amount}`);
          throw new Error('Insufficient wallet balance');
        }
        logger.info(`[StartSession] Wallet balance sufficient`);
      }

      // 3. Validate Station
      const station = await Charger.findOne({ charger_id: stationId });
      if (!station) {
        logger.error(`[StartSession] Station not found: ${stationId}`);
        throw new Error('Station not found');
      }
      
      logger.info(`[StartSession] Station found: ${stationId}, Status: ${station.status}`);

      if (station.status === 'offline') {
          logger.warn(`Station ${stationId} is marked offline in DB. Blocking startSession.`);
          throw new Error('Station is offline');
      }
      
      // 3. Create Session Record (Pending)
      // Generate 7-digit Session ID
      const sessionId = Math.floor(1000000 + Math.random() * 9000000);
      
      logger.info(`Creating ChargingSession: ${sessionId} for user ${user.user_id}`);
      
      const session = await ChargingSession.create({
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
        unit_price: station.price_per_kwh || 15.0, // Default to 15 if not set
        amount_to_charge: amount, // Save amount to charge for SOC simulation
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

    } catch (error: any) {
      logger.error('Error starting session', error.message);
      if (error.stack) logger.error(error.stack);
      throw error;
    }
  }

  static async stopSession(userEmail: string, sessionId: string) {
    try {
      const session = await ChargingSession.findOne({ session_id: Number(sessionId) });
      
      if (!session) {
         throw new Error('Session not found');
      }

      if (session.email_id !== userEmail) {
         throw new Error('Unauthorized');
      }

      // Check if session is stuck in 'stopping' state
      if (session.charger_status && session.charger_status.toLowerCase() === 'stopping') {
          const lastUpdate = new Date(session.modified_date);
          const now = new Date();
          const diffSeconds = (now.getTime() - lastUpdate.getTime()) / 1000;
          
          if (diffSeconds > 30) { // 30 seconds timeout
              logger.warn(`Session ${sessionId} stuck in stopping state for ${diffSeconds}s. Forcing completion.`);
              
              session.charger_status = 'Completed';
              session.stop_time = now;
              session.stop_reason = 'ForceStop_Timeout';
              
               // Ensure price/cost is final
              if (!session.consumed_amount) session.consumed_amount = session.price || 0;
              
              await session.save();
              
              return {
                  status: 'stopped_timeout',
                  message: 'Session force stopped (Timeout)'
              };
          }
      }

      if (['completed', 'failed', 'stopped'].includes(session.charger_status)) {
         throw new Error('Session already ended');
      }

      // 0. Check Station Status First
      const station = await Charger.findOne({ charger_id: session.charger_id });
      let isOffline = !station || station.status === 'offline';

      if (isOffline) {
          logger.warn(`Station ${session.charger_id} is offline. Forcing session stop.`);
          
          // Force Stop Logic
          session.charger_status = 'Completed';
          session.stop_time = new Date(); // Update stop_time
          session.stop_reason = 'ForceStop_Offline';
          
          // Ensure price/cost is final (fallback to last known)
          if (!session.consumed_amount) session.consumed_amount = session.price || 0;
          
          await session.save();
          
          return {
              status: 'stopped_offline',
              message: 'Session force stopped (Charger Offline)'
          };
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

    } catch (error) {
      logger.error('Error stopping session', error);
      throw error;
    }
  }

  static async checkConnectorStatus(stationId: string, connectorId: string | number, userId: string) {
    const station = await Charger.findOne({ charger_id: stationId });

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

    // Check for Lock
    const lockKey = `lock:${stationId}:${connectorId}`;
    const existingLock = await redis.get(lockKey);

    if (existingLock && existingLock !== userId) {
       throw new Error('Connector is currently being accessed by another user');
    }

    // Set Lock (TTL 5 minutes)
    await redis.set(lockKey, userId, 300);

    // If locked by current user, we ALLOW 'Preparing' status.
    // This handles the case where the user entered the page (triggering Preparing)
    // and then swipes to start.
    if (connector.status.toLowerCase() === 'preparing' && existingLock === userId) {
        logger.info(`Allowing 'Preparing' status for user ${userId} on ${stationId}:${connectorId} (Self-Locked)`);
    } else if (connector.status.toLowerCase() === 'charging') {
        // Check if this user owns the active session on this connector
        const activeSession = await ChargingSession.findOne({
            charger_id: stationId,
            connector_id: Number(connectorId),
            email_id: userId,
            charger_status: { $in: ['Charging', 'SuspendedEV', 'SuspendedEVSE'] }
        });

        if (activeSession) {
            logger.info(`User ${userId} attempting to access own active session on ${stationId}:${connectorId}`);
            return {
                allowed: false,
                activeSession: true,
                sessionId: activeSession.session_id,
                message: 'Active session found'
            };
        } else {
             throw new Error(`Connector is ${connector.status}`);
        }
    } else if (connector.status.toLowerCase() !== 'available') {
        throw new Error(`Connector is ${connector.status}`);
    }

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

  static async releaseLock(stationId: string, connectorId: string | number, userId: string) {
    const lockKey = `lock:${stationId}:${connectorId}`;
    const existingLock = await redis.get(lockKey);
    
    if (existingLock === userId) {
        await redis.del(lockKey);
        return { released: true };
    }
    return { released: false, reason: 'Lock not held by user' };
  }

  static async getActiveSession(userId: string) {
    const session = await ChargingSession.findOne({
      email_id: userId,
      charger_status: { $nin: ['completed', 'failed', 'stopped', 'Completed', 'Failed', 'Stopped'] } // Case insensitive safety or include both cases
    }).sort({ created_date: -1 });
    
    if (session) {
        // Fetch Charger Details
        const charger = await Charger.findOne({ charger_id: session.charger_id });
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

  static async getHistory(userId: string) {
    // Find all sessions for this user, sorted by date desc
    const sessions = await ChargingSession.find({ email_id: userId })
      .sort({ created_date: -1 })
      .lean();

    // Enrich with station name
    const enrichedSessions = await Promise.all(sessions.map(async (session: any) => {
        const charger = await Charger.findOne({ charger_id: session.charger_id }).select('name').lean();
        return {
            ...session,
            station_name: charger ? charger.name : 'Unknown Station'
        };
    }));

    return enrichedSessions;
  }

  static async getSessionDetails(userId: string, sessionId: string) {
      const session = await ChargingSession.findOne({ 
          session_id: Number(sessionId),
          email_id: userId
      });
      if (!session) throw new Error('Session not found');
      return session;
  }
}
