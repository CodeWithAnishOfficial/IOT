import { Router } from 'express';
import { WalletController } from '../controllers/wallet.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

router.use(authMiddleware); // Protect all wallet routes

// Route: GET /wallet/balance
// Description: Get current wallet balance
router.get('/balance', WalletController.getBalance);

// Route: POST /wallet/add-money
// Description: Initiate adding money to wallet (create order)
router.post('/add-money', WalletController.addMoney);

// Route: POST /wallet/verify-payment
// Description: Verify payment gateway response and update wallet
router.post('/verify-payment', WalletController.verifyPayment);

// Route: POST /wallet/refund
// Description: Request a refund for a transaction
router.post('/refund', WalletController.requestRefund);

// Route: GET /wallet/transactions
// Description: Get wallet transaction history
router.get('/transactions', WalletController.getTransactions);

export default router;
