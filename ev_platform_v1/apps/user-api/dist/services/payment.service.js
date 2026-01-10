"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentService = void 0;
const razorpay_1 = __importDefault(require("razorpay"));
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('PaymentService');
class PaymentService {
    razorpay;
    constructor() {
        // Explicitly using the provided test keys to ensure frontend/backend match
        this.razorpay = new razorpay_1.default({
            key_id: 'rzp_test_D9PcSutYWQ2e71',
            key_secret: 'ePodSzbZwF5MLu7obBB2vhlC',
        });
    }
    async createOrder(amount, receipt) {
        try {
            const options = {
                amount: Math.round(amount * 100), // Amount in paisa
                currency: 'INR',
                receipt,
            };
            const order = await this.razorpay.orders.create(options);
            return order;
        }
        catch (error) {
            logger.error('Error creating Razorpay order', error);
            throw error;
        }
    }
    async verifyPayment(orderId, paymentId, signature) {
        const crypto = require('crypto');
        const hmac = crypto.createHmac('sha256', process.env.RAZORPAY_KEY_SECRET || 'ePodSzbZwF5MLu7obBB2vhlC');
        hmac.update(orderId + '|' + paymentId);
        const generatedSignature = hmac.digest('hex');
        return generatedSignature === signature;
    }
}
exports.PaymentService = PaymentService;
//# sourceMappingURL=payment.service.js.map