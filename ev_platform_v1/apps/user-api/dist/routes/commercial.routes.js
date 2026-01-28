"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const commercial_controller_1 = require("../controllers/commercial.controller");
const auth_middleware_1 = require("../middlewares/auth.middleware");
const router = (0, express_1.Router)();
router.use(auth_middleware_1.authMiddleware);
router.post('/charger', commercial_controller_1.CommercialController.addCharger);
router.get('/chargers', commercial_controller_1.CommercialController.getMyChargers);
router.get('/analytics', commercial_controller_1.CommercialController.getAnalytics);
router.get('/wallet', commercial_controller_1.CommercialController.getWalletHistory);
exports.default = router;
//# sourceMappingURL=commercial.routes.js.map