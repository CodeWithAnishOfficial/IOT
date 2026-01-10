import { Router } from 'express';
import { ChargerController } from '../controllers/charger.controller';

const router = Router();

// Route: GET /chargers/list
// Description: List all chargers
router.get('/list', ChargerController.getAllChargers);

// Route: POST /chargers/create
// Description: Create a new charger
router.post('/create', ChargerController.createCharger);

// Route: GET /chargers/details/:id
// Description: Get details of a specific charger
router.get('/details/:id', ChargerController.getChargerById);

// Route: PUT /chargers/update/:id
// Description: Update charger details
router.put('/update/:id', ChargerController.updateCharger);

// Route: DELETE /chargers/delete/:id
// Description: Delete a charger
router.delete('/delete/:id', ChargerController.deleteCharger);

export default router;
