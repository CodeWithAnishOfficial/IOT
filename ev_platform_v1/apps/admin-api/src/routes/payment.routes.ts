import { Router } from 'express';
import { PaymentController } from '../controllers/payment.controller';

const router = Router();

// Route: GET /payments/history
// Description: Get payment history
router.get('/history', PaymentController.getHistory);

export default router;
