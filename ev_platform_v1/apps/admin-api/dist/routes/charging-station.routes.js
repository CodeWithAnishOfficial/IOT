"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const charging_station_controller_1 = require("../controllers/charging-station.controller");
const router = (0, express_1.Router)();
// Route: GET /charging-stations/list
// Description: List all charging stations
router.get('/list', charging_station_controller_1.ChargingStationController.getAllStations);
// Route: POST /charging-stations/create
// Description: Create a new charging station
router.post('/create', charging_station_controller_1.ChargingStationController.createStation);
// Route: GET /charging-stations/details/:id
// Description: Get details of a specific charging station
router.get('/details/:id', charging_station_controller_1.ChargingStationController.getStationById);
// Route: PUT /charging-stations/update/:id
// Description: Update charging station details
router.put('/update/:id', charging_station_controller_1.ChargingStationController.updateStation);
// Route: DELETE /charging-stations/delete/:id
// Description: Delete a charging station
router.delete('/delete/:id', charging_station_controller_1.ChargingStationController.deleteStation);
exports.default = router;
//# sourceMappingURL=charging-station.routes.js.map