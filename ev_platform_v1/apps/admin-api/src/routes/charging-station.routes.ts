import { Router } from 'express';
import { ChargingStationController } from '../controllers/charging-station.controller';

const router = Router();

router.get('/', ChargingStationController.getAllStations);
router.post('/', ChargingStationController.createStation);
router.get('/:id', ChargingStationController.getStationById);
router.put('/:id', ChargingStationController.updateStation);

export default router;
