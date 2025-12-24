import { Router } from 'express';
import { VehicleController } from '../controllers/vehicle.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

router.use(authMiddleware);

router.post('/', VehicleController.addVehicle);
router.get('/', VehicleController.getVehicles);
router.delete('/:id', VehicleController.deleteVehicle);

export default router;
