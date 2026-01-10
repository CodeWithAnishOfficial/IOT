import { Router } from 'express';
import { AdminSavedTripController } from '../controllers/saved_trip.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

router.use(authMiddleware);

router.get('/', AdminSavedTripController.getAllSavedTrips);
router.get('/:id', AdminSavedTripController.getSavedTripDetails);

export default router;
