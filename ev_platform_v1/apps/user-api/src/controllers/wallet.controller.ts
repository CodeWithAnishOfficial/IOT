import { Request, Response } from 'express';
import { User, WalletTransaction, Logger } from '@ev-platform-v1/shared';
import { PaymentService } from '../services/payment.service';
import { v4 as uuidv4 } from 'uuid';

const logger = new Logger('WalletController');
const paymentService = new PaymentService();

export class WalletController {
  static async getBalance(req: Request, res: Response) {
    try {
      // @ts-ignore - user_id injected by auth middleware
      const userId = req.user?.email_id; 
      const user = await User.findOne({ email_id: userId });
      if (!user) return res.status(404).json({ error: true, message: 'User not found' });

      res.json({ error: false, balance: user.wallet_bal });
    } catch (error: any) {
      logger.error('Error fetching balance', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async addMoney(req: Request, res: Response) {
    try {
      const { amount } = req.body;
      // @ts-ignore
      const userId = req.user?.email_id;

      if (!amount || amount <= 0) {
        return res.status(400).json({ error: true, message: 'Invalid amount' });
      }

      const receiptId = `rcpt_${uuidv4()}`;
      const order = await paymentService.createOrder(amount, receiptId);

      res.json({
        error: false,
        message: 'Order created',
        data: order
      });
    } catch (error: any) {
      logger.error('Error adding money', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async verifyPayment(req: Request, res: Response) {
    try {
      const { razorpay_order_id, razorpay_payment_id, razorpay_signature, amount } = req.body;
      // @ts-ignore
      const userId = req.user?.email_id;

      const isValid = await paymentService.verifyPayment(razorpay_order_id, razorpay_payment_id, razorpay_signature);

      if (!isValid) {
        return res.status(400).json({ error: true, message: 'Invalid payment signature' });
      }

      // Update User Wallet
      const user = await User.findOne({ email_id: userId });
      if (!user) return res.status(404).json({ error: true, message: 'User not found' });

      user.wallet_bal += amount;
      await user.save();

      // Log Transaction
      await WalletTransaction.create({
        transaction_id: razorpay_payment_id,
        user_id: userId,
        amount: amount,
        type: 'credit',
        source: 'razorpay',
        reference_id: razorpay_order_id,
        status: 'success'
      });

      res.json({ error: false, message: 'Payment successful, wallet updated', newBalance: user.wallet_bal });
    } catch (error: any) {
      logger.error('Error verifying payment', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async getTransactions(req: Request, res: Response) {
    try {
      // @ts-ignore
      const userId = req.user?.email_id;
      const transactions = await WalletTransaction.find({ user_id: userId }).sort({ created_at: -1 });
      res.json({ error: false, data: transactions });
    } catch (error: any) {
      logger.error('Error fetching transactions', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async requestRefund(req: Request, res: Response) {
    try {
      const { transaction_id, reason } = req.body;
      // @ts-ignore
      const userId = req.user?.email_id;

      const transaction = await WalletTransaction.findOne({ 
        transaction_id, 
        user_id: userId 
      });

      if (!transaction) {
        return res.status(404).json({ error: true, message: 'Transaction not found' });
      }

      // In a real system, this would trigger a gateway refund or create a support ticket
      // For now, we'll just log it
      logger.info(`Refund requested for ${transaction_id} by ${userId}: ${reason}`);

      res.json({ error: false, message: 'Refund request submitted successfully' });
    } catch (error: any) {
      logger.error('Error requesting refund', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }
}
