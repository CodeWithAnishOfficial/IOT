import Razorpay from 'razorpay';
import { Logger } from '@ev-platform-v1/shared';

const logger = new Logger('PaymentService');

export class PaymentService {
  private razorpay: Razorpay;

  constructor() {
    this.razorpay = new Razorpay({
      key_id: process.env.RAZORPAY_KEY_ID || 'test_key',
      key_secret: process.env.RAZORPAY_KEY_SECRET || 'test_secret',
    });
  }

  async createOrder(amount: number, receipt: string) {
    try {
      const options = {
        amount: amount * 100, // Amount in paisa
        currency: 'INR',
        receipt,
      };
      const order = await this.razorpay.orders.create(options);
      return order;
    } catch (error) {
      logger.error('Error creating Razorpay order', error);
      throw error;
    }
  }

  async verifyPayment(orderId: string, paymentId: string, signature: string) {
    const crypto = require('crypto');
    const hmac = crypto.createHmac('sha256', process.env.RAZORPAY_KEY_SECRET || 'test_secret');
    hmac.update(orderId + '|' + paymentId);
    const generatedSignature = hmac.digest('hex');

    return generatedSignature === signature;
  }
}
