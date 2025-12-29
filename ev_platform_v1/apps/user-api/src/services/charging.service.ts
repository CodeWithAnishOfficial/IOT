import { Logger, User, ChargingSession, RedisService, ChargingStation } from '@ev-platform-v1/shared';
import { v4 as uuidv4 } from 'uuid';
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
    try {
      // 1. Validate User
      const user = await User.findOne({ email_id: userId });
      if (!user) {
        throw new Error('User not found');
      }

      // 2. Validate Payment OR Balance
      let isDirectPayment = false;
      
      if (paymentDetails) {
        // Verify Razorpay Payment
        const isValid = await paymentService.verifyPayment(
          paymentDetails.orderId,
          paymentDetails.paymentId,
          paymentDetails.signature
        );
        
        if (!isValid) {
          throw new Error('Invalid payment signature');
        }
        
        isDirectPayment = true;
        logger.info(`Direct payment verified for user ${userId}: ${paymentDetails.paymentId}`);
        
      } else {
        // Fallback to Wallet Check
        if (user.wallet_bal < amount) {
          throw new Error('Insufficient wallet balance');
        }
      }

      // 3. Validate Station
      const station = await ChargingStation.findOne({ charger_id: stationId });
      if (!station) {
        throw new Error('Station not found');
      }
      
      // 3. Create Session Record (Pending)
      const sessionId = uuidv4();
      const session = await ChargingSession.create({
        session_id: sessionId,
        user_id: userId,
        charger_id: stationId,
        connector_id: Number(connectorId),
        status: 'pending', // Waiting for charger to accept
        start_time: new Date(),
        cost: 0, // Will be updated on completion
        total_energy: 0
      });

      // 4. Publish Command to OCPP Server via Redis
      // The OCPP Server listens to 'ocpp:commands' and sends RemoteStartTransaction to charger
      const commandPayload = {
        chargerId: stationId,
        command: 'RemoteStartTransaction',
        payload: {
          connectorId: Number(connectorId),
          idTag: userId.substring(0, 20), // Truncate if needed, usually RFID or User ID
          // Optional: ChargingProfile for limit
        }
      };

      await redis.publish('ocpp:commands', commandPayload);
      logger.info(`Published RemoteStartTransaction for ${stationId}:${connectorId} by ${userId}`);

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

    } catch (error) {
      logger.error('Error starting session', error);
      throw error;
    }
  }

  static async stopSession(userId: string, sessionId: string) {
    try {
      const session = await ChargingSession.findOne({ session_id: sessionId });
      
      if (!session) {
         throw new Error('Session not found');
      }

      if (session.user_id !== userId) {
         throw new Error('Unauthorized');
      }

      if (['completed', 'failed', 'stopped'].includes(session.status)) {
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
      
      session.status = 'stopping';
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
}
