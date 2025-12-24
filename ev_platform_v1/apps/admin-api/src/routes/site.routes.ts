import { Router } from 'express';
import { SiteController } from '../controllers/site.controller';

const router = Router();

router.get('/', SiteController.getAllSites);
router.post('/', SiteController.createSite);
router.get('/:id', SiteController.getSiteById);
router.put('/:id', SiteController.updateSite);
router.delete('/:id', SiteController.deleteSite);

export default router;
