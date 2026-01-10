"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.WalletController = void 0;
const shared_1 = require("@ev-platform-v1/shared");
const payment_service_1 = require("../services/payment.service");
const uuid_1 = require("uuid");
const logger = new shared_1.Logger('WalletController');
const paymentService = new payment_service_1.PaymentService();
class WalletController {
    static async getBalance(req, res) {
        try {
            // @ts-ignore - user_id injected by auth middleware
            const userId = req.user?.email_id;
            const user = await shared_1.User.findOne({ email_id: userId });
            if (!user)
                return res.status(404).json({ error: true, message: 'User not found' });
            res.json({ error: false, balance: user.wallet_bal });
        }
        catch (error) {
            logger.error('Error fetching balance', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async addMoney(req, res) {
        try {
            const { amount } = req.body;
            // @ts-ignore
            const userId = req.user?.email_id;
            if (!amount || amount <= 0) {
                return res.status(400).json({ error: true, message: 'Invalid amount' });
            }
            const receiptId = `rcpt_${(0, uuid_1.v4)()}`;
            const order = await paymentService.createOrder(amount, receiptId);
            res.json({
                error: false,
                message: 'Order created',
                data: order
            });
        }
        catch (error) {
            logger.error('Error adding money', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async verifyPayment(req, res) {
        try {
            const { razorpay_order_id, razorpay_payment_id, razorpay_signature, amount } = req.body;
            // @ts-ignore
            const userId = req.user?.email_id;
            const isValid = await paymentService.verifyPayment(razorpay_order_id, razorpay_payment_id, razorpay_signature);
            if (!isValid) {
                return res.status(400).json({ error: true, message: 'Invalid payment signature' });
            }
            // Update User Wallet
            const user = await shared_1.User.findOne({ email_id: userId });
            if (!user)
                return res.status(404).json({ error: true, message: 'User not found' });
            user.wallet_bal += amount;
            await user.save();
            // Log Transaction
            await shared_1.WalletTransaction.create({
                transaction_id: razorpay_payment_id,
                user_id: userId,
                amount: amount,
                type: 'credit',
                source: 'razorpay',
                reference_id: razorpay_order_id,
                status: 'success'
            });
            res.json({ error: false, message: 'Payment successful, wallet updated', newBalance: user.wallet_bal });
        }
        catch (error) {
            logger.error('Error verifying payment', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async getTransactions(req, res) {
        try {
            // @ts-ignore
            const emailId = req.user?.email_id;
            // Fetch payments from Payment collection where email_id matches
            // Sorting by recharged_date descending
            const transactions = await shared_1.Payment.find({ email_id: emailId }).sort({ recharged_date: -1 });
            res.json({ error: false, data: transactions });
        }
        catch (error) {
            logger.error('Error fetching transactions', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async requestRefund(req, res) {
        try {
            const { transaction_id, reason } = req.body;
            // @ts-ignore
            const userId = req.user?.email_id;
            const transaction = await shared_1.WalletTransaction.findOne({
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
        }
        catch (error) {
            logger.error('Error requesting refund', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
}
exports.WalletController = WalletController;
//# sourceMappingURL=wallet.controller.js.map