import { Router } from 'express';
import { CommercialController } from '../controllers/commercial.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

router.use(authMiddleware);

router.post('/charger', CommercialController.addCharger);
router.get('/chargers', CommercialController.getMyChargers);
router.get('/analytics', CommercialController.getAnalytics);
router.get('/wallet', CommercialController.getWalletHistory);

export default router;
