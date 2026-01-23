import { Request, Response } from 'express';
import { Payment, Logger } from '@ev-platform-v1/shared';

const logger = new Logger('PaymentController');

export class PaymentController {
  static async getHistory(req: Request, res: Response) {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 10;
      const skip = (page - 1) * limit;

      const payments = await Payment.find()
        .sort({ recharged_date: -1 })
        .skip(skip)
        .limit(limit);

      const total = await Payment.countDocuments();

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
    } catch (error: any) {
      logger.error('Error fetching payment history', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }
}
