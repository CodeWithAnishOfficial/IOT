"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentController = void 0;
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('PaymentController');
class PaymentController {
    static async getHistory(req, res) {
        try {
            const page = parseInt(req.query.page) || 1;
            const limit = parseInt(req.query.limit) || 10;
            const skip = (page - 1) * limit;
            const payments = await shared_1.Payment.find()
                .sort({ recharged_date: -1 })
                .skip(skip)
                .limit(limit);
            const total = await shared_1.Payment.countDocuments();
            res.json({
                error: false,
                data: payments,
                pagination: {
                    total,
                    page,
                    limit,
                    pages: Math.ceil(total / limit)
                }
            });
        }
        catch (error) {
            logger.error('Error fetching payment history', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
}
exports.PaymentController = PaymentController;
//# sourceMappingURL=payment.controller.js.map