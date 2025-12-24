import { User, WalletTransaction, Logger, ChargingSession } from '@ev-platform-v1/shared';
import { v4 as uuidv4 } from 'uuid';
import { TariffService } from './tariff.service';

const logger = new Logger('BillingService');

export class BillingService {

  public static async processCDR(data: any) {
    logger.info(`Processing CDR for transaction ${data.transactionId}`);
    
    try {
      const { transactionId, userId, totalEnergy, sessionId, chargerId, timestamp } = data;

      if (!userId) {
        logger.warn(`No user ID associated with transaction ${transactionId}, skipping billing`);
        return;
      }

      // Calculate Cost using Tariff Engine
      // We need start time. Timestamp in CDR is usually stop time.
      // We can fetch session to get start time.
      let startTime = new Date();
      if (sessionId) {
          const session = await ChargingSession.findOne({ session_id: sessionId });
          if (session) {
              startTime = session.start_time;
          }
      }

      // Duration: if we have start and stop time. For now passing 0 if unknown.
      // TariffService might need start time to determine TOU.
      const cost = await TariffService.calculateCost(totalEnergy, 0, startTime, chargerId);
      
      const user = await User.findOne({ email_id: userId });
      if (!user) {
        logger.error(`User ${userId} not found for billing`);
        return;
      }

      // Deduct from wallet
      user.wallet_bal -= cost;
      await user.save();

      // Create Wallet Transaction
      await WalletTransaction.create({
        transaction_id: `bill_${transactionId}`,
        user_id: userId,
        amount: cost,
        type: 'debit',
        source: 'charging_session',
        reference_id: sessionId || transactionId.toString(),
        status: 'success'
      });

      // Update Session with cost
      if (sessionId) {
          await ChargingSession.updateOne(
              { session_id: sessionId },
              { $set: { cost: cost, currency: 'INR' } } // Assuming schema supports cost/currency, if not it will be ignored or error depending on strictness
          );
      }

      logger.info(`Billed user ${userId} ${cost} for ${totalEnergy} kWh`);

    } catch (error) {
      logger.error(`Error processing CDR for ${data.transactionId}`, error);
      throw error; // Re-throw to allow RabbitMQ to nack/retry
    }
  }
}
