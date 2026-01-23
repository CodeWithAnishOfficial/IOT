"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const saved_trip_controller_1 = require("../controllers/saved_trip.controller");
const auth_middleware_1 = require("../middlewares/auth.middleware");
const router = (0, express_1.Router)();
router.use(auth_middleware_1.authMiddleware);
router.get('/', saved_trip_controller_1.AdminSavedTripController.getAllSavedTrips);
router.get('/:id', saved_trip_controller_1.AdminSavedTripController.getSavedTripDetails);
exports.default = router;
//# sourceMappingURL=saved_trip.routes.js.map