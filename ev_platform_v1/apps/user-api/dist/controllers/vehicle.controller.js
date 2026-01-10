"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.VehicleController = void 0;
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('VehicleController');
class VehicleController {
    static async addVehicle(req, res) {
        try {
            // @ts-ignore
            const userId = req.user.email_id;
            const { make, model, year, vin, plate_no, connector_type } = req.body;
            const vehicle = await shared_1.Vehicle.create({
                user_id: userId,
                make,
                modelName: model,
                year,
                vin,
                plate_no,
                connector_type
            });
            res.status(201).json({ error: false, message: 'Vehicle added', data: vehicle });
        }
        catch (error) {
            logger.error('Error adding vehicle', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async getVehicles(req, res) {
        try {
            // @ts-ignore
            const userId = req.user.email_id;
            const vehicles = await shared_1.Vehicle.find({ user_id: userId });
            res.json({ error: false, data: vehicles });
        }
        catch (error) {
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async deleteVehicle(req, res) {
        try {
            const { id } = req.params;
            // @ts-ignore
            const userId = req.user.email_id;
            await shared_1.Vehicle.findOneAndDelete({ _id: id, user_id: userId });
            res.json({ error: false, message: 'Vehicle deleted' });
        }
        catch (error) {
            res.status(500).json({ error: true, message: error.message });
        }
    }
}
exports.VehicleController = VehicleController;
//# sourceMappingURL=vehicle.controller.js.map