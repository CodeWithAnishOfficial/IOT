import { Router } from 'express';
import { SiteController } from '../controllers/site.controller';
import { upload } from '../middlewares/upload.middleware';

const router = Router();

// Route: POST /sites/upload
// Description: Upload an image
router.post('/upload', upload.single('image'), SiteController.uploadImage);

// Route: GET /sites/list
// Description: List all sites
router.get('/list', SiteController.getAllSites);

// Route: POST /sites/create
// Description: Create a new site
router.post('/create', SiteController.createSite);

// Route: GET /sites/details/:id
// Description: Get details of a specific site
router.get('/details/:id', SiteController.getSiteById);

// Route: PUT /sites/update/:id
// Description: Update site details
router.put('/update/:id', SiteController.updateSite);

// Route: DELETE /sites/delete/:id
// Description: Delete a site
router.delete('/delete/:id', SiteController.deleteSite);

export default router;
