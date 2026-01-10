"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const tariff_controller_1 = require("../controllers/tariff.controller");
const router = (0, express_1.Router)();
// Route: GET /tariffs/list
// Description: List all tariffs
router.get('/list', tariff_controller_1.TariffController.getAllTariffs);
// Route: POST /tariffs/create
// Description: Create a new tariff plan
router.post('/create', tariff_controller_1.TariffController.createTariff);
// Route: PUT /tariffs/update/:id
// Description: Update an existing tariff plan
router.put('/update/:id', tariff_controller_1.TariffController.updateTariff);
// Route: DELETE /tariffs/delete/:id
// Description: Delete a tariff plan
router.delete('/delete/:id', tariff_controller_1.TariffController.deleteTariff);
exports.default = router;
//# sourceMappingURL=tariff.routes.js.map