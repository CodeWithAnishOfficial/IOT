"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TariffController = void 0;
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('TariffController');
class TariffController {
    static async createTariff(req, res) {
        try {
            const tariff = await shared_1.Tariff.create(req.body);
            res.status(201).json({ error: false, message: 'Tariff created', data: tariff });
        }
        catch (error) {
            logger.error('Error creating tariff', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async getAllTariffs(req, res) {
        try {
            const tariffs = await shared_1.Tariff.find().sort({ created_at: -1 });
            res.json({ error: false, data: tariffs });
        }
        catch (error) {
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async updateTariff(req, res) {
        try {
            const { id } = req.params;
            const tariff = await shared_1.Tariff.findByIdAndUpdate(id, req.body, { new: true });
            if (!tariff)
                return res.status(404).json({ error: true, message: 'Tariff not found' });
            res.json({ error: false, message: 'Tariff updated', data: tariff });
        }
        catch (error) {
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async deleteTariff(req, res) {
        try {
            const { id } = req.params;
            const stationsCount = await shared_1.Charger.countDocuments({ tariff_id: id });
            if (stationsCount > 0) {
                return res.status(400).json({ error: true, message: `Cannot delete tariff. It is assigned to ${stationsCount} stations.` });
            }
            await shared_1.Tariff.findByIdAndDelete(id);
            res.json({ error: false, message: 'Tariff deleted' });
        }
        catch (error) {
            res.status(500).json({ error: true, message: error.message });
        }
    }
}
exports.TariffController = TariffController;
//# sourceMappingURL=tariff.controller.js.map