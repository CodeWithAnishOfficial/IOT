import { Router } from 'express';
import { ChargingStationController } from '../controllers/charging-station.controller';

const router = Router();

// Route: GET /charging-stations/list
// Description: List all charging stations
router.get('/list', ChargingStationController.getAllStations);

// Route: POST /charging-stations/create
// Description: Create a new charging station
router.post('/create', ChargingStationController.createStation);

// Route: GET /charging-stations/details/:id
// Description: Get details of a specific charging station
router.get('/details/:id', ChargingStationController.getStationById);

// Route: PUT /charging-stations/update/:id
// Description: Update charging station details
router.put('/update/:id', ChargingStationController.updateStation);

// Route: DELETE /charging-stations/delete/:id
// Description: Delete a charging station
router.delete('/delete/:id', ChargingStationController.deleteStation);

export default router;
