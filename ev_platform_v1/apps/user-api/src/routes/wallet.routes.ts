import { Router } from 'express';
import { WalletController } from '../controllers/wallet.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

router.use(authMiddleware); // Protect all wallet routes

router.get('/balance', WalletController.getBalance);
router.post('/add-money', WalletController.addMoney);
router.post('/verify-payment', WalletController.verifyPayment);
router.get('/transactions', WalletController.getTransactions);

export default router;
