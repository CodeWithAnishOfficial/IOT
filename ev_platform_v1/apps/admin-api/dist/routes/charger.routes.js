"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const charger_controller_1 = require("../controllers/charger.controller");
const router = (0, express_1.Router)();
// Route: GET /chargers/list
// Description: List all chargers
router.get('/list', charger_controller_1.ChargerController.getAllChargers);
// Route: POST /chargers/create
// Description: Create a new charger
router.post('/create', charger_controller_1.ChargerController.createCharger);
// Route: GET /chargers/details/:id
// Description: Get details of a specific charger
router.get('/details/:id', charger_controller_1.ChargerController.getChargerById);
// Route: PUT /chargers/update/:id
// Description: Update charger details
router.put('/update/:id', charger_controller_1.ChargerController.updateCharger);
// Route: DELETE /chargers/delete/:id
// Description: Delete a charger
router.delete('/delete/:id', charger_controller_1.ChargerController.deleteCharger);
exports.default = router;
//# sourceMappingURL=charger.routes.js.map