"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const charging_controller_1 = require("../controllers/charging.controller");
const auth_middleware_1 = require("../middlewares/auth.middleware");
const router = (0, express_1.Router)();
router.use(auth_middleware_1.authMiddleware);
// Route: GET /charging/active-session
// Description: Get current active session
router.get('/active-session', charging_controller_1.ChargingController.getActiveSession);
// Route: GET /charging/history
// Description: Get charging history
router.get('/history', charging_controller_1.ChargingController.getHistory);
// Route: GET /charging/invoice/:session_id
// Description: Download invoice PDF
router.get('/invoice/:session_id', charging_controller_1.ChargingController.downloadInvoice);
// Route: GET /charging/status
// Description: Check connector status
router.get('/status', charging_controller_1.ChargingController.checkStatus);
// Route: POST /charging/release
// Description: Release connector lock
router.post('/release', charging_controller_1.ChargingController.releaseLock);
// Route: POST /charging/start
// Description: Start a charging session
router.post('/start', charging_controller_1.ChargingController.start);
// Route: POST /charging/initiate-payment
// Description: Create Razorpay order for charging
router.post('/initiate-payment', charging_controller_1.ChargingController.initiatePayment);
// Route: POST /charging/stop
// Description: Stop a charging session
router.post('/stop', charging_controller_1.ChargingController.stop);
exports.default = router;
//# sourceMappingURL=charging.routes.js.map