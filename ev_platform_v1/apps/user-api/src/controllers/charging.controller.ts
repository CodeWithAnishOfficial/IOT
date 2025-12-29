import { Request, Response } from 'express';
import { Logger } from '@ev-platform-v1/shared';
import { ChargingService } from '../services/charging.service';
import { PaymentService } from '../services/payment.service';
import { v4 as uuidv4 } from 'uuid';

const logger = new Logger('ChargingController');
const paymentService = new PaymentService();

export class ChargingController {
  
  static async initiatePayment(req: Request, res: Response) {
    try {
      const { amount } = req.body;
      if (!amount) {
        return res.status(400).json({ error: true, message: 'Amount is required' });
      }

      const receiptId = `chg_${uuidv4()}`;
      const order = await paymentService.createOrder(Number(amount), receiptId);

      res.json({
        error: false,
        message: 'Order created',
        data: order
      });
    } catch (error: any) {
      logger.error('Error initiating payment', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async start(req: Request, res: Response) {
    try {
      // @ts-ignore
      const userId = req.user?.email_id;
      const { station_id, connector_id, amount, payment_details } = req.body;

      if (!station_id || !connector_id || !amount) {
        return res.status(400).json({ error: true, message: 'Missing required fields' });
      }

      const result = await ChargingService.startSession(
        userId, 
        station_id, 
        connector_id, 
        Number(amount),
        payment_details // Optional: { orderId, paymentId, signature }
      );

      res.json({
        error: false,
        message: 'Charging initiated',
        data: result
      });

    } catch (error: any) {
      logger.error('Error in start charging', error);
      res.status(500).json({ 
        error: true, 
        message: error.message || 'Failed to start charging session' 
      });
    }
  }

  static async stop(req: Request, res: Response) {
    try {
      // @ts-ignore
      const userId = req.user?.email_id;
      const { session_id } = req.body;

      if (!session_id) {
        return res.status(400).json({ error: true, message: 'Missing session_id' });
      }

      const result = await ChargingService.stopSession(userId, session_id);

      res.json({
        error: false,
        message: 'Stop command initiated',
        data: result
      });

    } catch (error: any) {
      logger.error('Error in stop charging', error);
      res.status(500).json({ 
        error: true, 
        message: error.message || 'Failed to stop charging session' 
      });
    }
  }
}
