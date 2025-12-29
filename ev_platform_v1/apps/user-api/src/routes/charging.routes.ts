import { Router } from 'express';
import { ChargingController } from '../controllers/charging.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

router.use(authMiddleware);

// Route: POST /charging/start
// Description: Start a charging session
router.post('/start', ChargingController.start);

// Route: POST /charging/initiate-payment
// Description: Create Razorpay order for charging
router.post('/initiate-payment', ChargingController.initiatePayment);

// Route: POST /charging/stop
// Description: Stop a charging session
router.post('/stop', ChargingController.stop);

export default router;
