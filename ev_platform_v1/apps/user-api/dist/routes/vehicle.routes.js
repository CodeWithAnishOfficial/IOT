"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const vehicle_controller_1 = require("../controllers/vehicle.controller");
const auth_middleware_1 = require("../middlewares/auth.middleware");
const router = (0, express_1.Router)();
router.use(auth_middleware_1.authMiddleware);
// Route: POST /vehicles/add
// Description: Add a new vehicle to user's profile
router.post('/add', vehicle_controller_1.VehicleController.addVehicle);
// Route: GET /vehicles/list
// Description: List all vehicles belonging to the user
router.get('/list', vehicle_controller_1.VehicleController.getVehicles);
// Route: DELETE /vehicles/delete/:id
// Description: Remove a vehicle from user's profile
router.delete('/delete/:id', vehicle_controller_1.VehicleController.deleteVehicle);
exports.default = router;
//# sourceMappingURL=vehicle.routes.js.map