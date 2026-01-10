"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const site_controller_1 = require("../controllers/site.controller");
const upload_middleware_1 = require("../middlewares/upload.middleware");
const router = (0, express_1.Router)();
// Route: POST /sites/upload
// Description: Upload an image
router.post('/upload', upload_middleware_1.upload.single('image'), site_controller_1.SiteController.uploadImage);
// Route: GET /sites/list
// Description: List all sites
router.get('/list', site_controller_1.SiteController.getAllSites);
// Route: POST /sites/create
// Description: Create a new site
router.post('/create', site_controller_1.SiteController.createSite);
// Route: GET /sites/details/:id
// Description: Get details of a specific site
router.get('/details/:id', site_controller_1.SiteController.getSiteById);
// Route: PUT /sites/update/:id
// Description: Update site details
router.put('/update/:id', site_controller_1.SiteController.updateSite);
// Route: DELETE /sites/delete/:id
// Description: Delete a site
router.delete('/delete/:id', site_controller_1.SiteController.deleteSite);
exports.default = router;
//# sourceMappingURL=site.routes.js.map