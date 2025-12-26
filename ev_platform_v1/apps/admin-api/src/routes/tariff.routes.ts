import { Router } from 'express';
import { TariffController } from '../controllers/tariff.controller';

const router = Router();

// Route: GET /tariffs/list
// Description: List all tariffs
router.get('/list', TariffController.getAllTariffs);

// Route: POST /tariffs/create
// Description: Create a new tariff plan
router.post('/create', TariffController.createTariff);

// Route: PUT /tariffs/update/:id
// Description: Update an existing tariff plan
router.put('/update/:id', TariffController.updateTariff);

// Route: DELETE /tariffs/delete/:id
// Description: Delete a tariff plan
router.delete('/delete/:id', TariffController.deleteTariff);

export default router;
