import { Router } from 'express';
import { ChargingController } from '../controllers/charging.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

router.use(authMiddleware);

// Route: GET /charging/active-session
// Description: Get current active session
router.get('/active-session', ChargingController.getActiveSession);

// Route: GET /charging/history
// Description: Get charging history
router.get('/history', ChargingController.getHistory);

// Route: GET /charging/invoice/:session_id
// Description: Download invoice PDF
router.get('/invoice/:session_id', ChargingController.downloadInvoice);

// Route: GET /charging/status
// Description: Check connector status
router.get('/status', ChargingController.checkStatus);

// Route: POST /charging/release
// Description: Release connector lock
router.post('/release', ChargingController.releaseLock);

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
