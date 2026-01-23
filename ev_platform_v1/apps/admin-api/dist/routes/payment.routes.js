"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const payment_controller_1 = require("../controllers/payment.controller");
const router = (0, express_1.Router)();
// Route: GET /payments/history
// Description: Get payment history
router.get('/history', payment_controller_1.PaymentController.getHistory);
exports.default = router;
//# sourceMappingURL=payment.routes.js.map