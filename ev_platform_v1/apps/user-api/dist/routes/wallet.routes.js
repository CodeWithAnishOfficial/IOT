"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const wallet_controller_1 = require("../controllers/wallet.controller");
const auth_middleware_1 = require("../middlewares/auth.middleware");
const router = (0, express_1.Router)();
router.use(auth_middleware_1.authMiddleware); // Protect all wallet routes
// Route: GET /wallet/balance
// Description: Get current wallet balance
router.get('/balance', wallet_controller_1.WalletController.getBalance);
// Route: POST /wallet/add-money
// Description: Initiate adding money to wallet (create order)
router.post('/add-money', wallet_controller_1.WalletController.addMoney);
// Route: POST /wallet/verify-payment
// Description: Verify payment gateway response and update wallet
router.post('/verify-payment', wallet_controller_1.WalletController.verifyPayment);
// Route: POST /wallet/refund
// Description: Request a refund for a transaction
router.post('/refund', wallet_controller_1.WalletController.requestRefund);
// Route: GET /wallet/transactions
// Description: Get wallet transaction history
router.get('/transactions', wallet_controller_1.WalletController.getTransactions);
exports.default = router;
//# sourceMappingURL=wallet.routes.js.map