import { Router } from 'express';
import { VehicleController } from '../controllers/vehicle.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

router.use(authMiddleware);

// Route: POST /vehicles/add
// Description: Add a new vehicle to user's profile
router.post('/add', VehicleController.addVehicle);

// Route: GET /vehicles/list
// Description: List all vehicles belonging to the user
router.get('/list', VehicleController.getVehicles);

// Route: DELETE /vehicles/delete/:id
// Description: Remove a vehicle from user's profile
router.delete('/delete/:id', VehicleController.deleteVehicle);

export default router;
