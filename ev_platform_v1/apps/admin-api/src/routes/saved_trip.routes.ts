import { Router } from 'express';
import { AdminSavedTripController } from '../controllers/saved_trip.controller';

const router = Router();

router.get('/', AdminSavedTripController.getAllSavedTrips);
router.get('/:id', AdminSavedTripController.getSavedTripDetails);

export default router;
