import Razorpay from 'razorpay';
import { Logger } from '@ev-platform-v1/shared';

const logger = new Logger('PaymentService');

export class PaymentService {
  private razorpay: Razorpay;

  constructor() {
    this.razorpay = new Razorpay({
      key_id: process.env.RAZORPAY_KEY_ID || 'rzp_test_D9PcSutYWQ2e71',
      key_secret: process.env.RAZORPAY_KEY_SECRET || 'ePodSzbZwF5MLu7obBB2vhlC',
    });
  }

  async createOrder(amount: number, receipt: string) {
    try {
      const options = {
        amount: Math.round(amount * 100), // Amount in paisa
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
    const hmac = crypto.createHmac('sha256', process.env.RAZORPAY_KEY_SECRET || 'ePodSzbZwF5MLu7obBB2vhlC');
    hmac.update(orderId + '|' + paymentId);
    const generatedSignature = hmac.digest('hex');

    return generatedSignature === signature;
  }
}
