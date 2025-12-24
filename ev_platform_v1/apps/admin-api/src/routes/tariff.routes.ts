import { Router } from 'express';
import { TariffController } from '../controllers/tariff.controller';

const router = Router();

router.get('/', TariffController.getAllTariffs);
router.post('/', TariffController.createTariff);
router.put('/:id', TariffController.updateTariff);
router.delete('/:id', TariffController.deleteTariff);

export default router;
