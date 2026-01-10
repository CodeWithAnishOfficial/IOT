"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChargerController = void 0;
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('ChargerController');
class ChargerController {
    static async getAllChargers(req, res) {
        try {
            const chargers = await shared_1.Charger.find();
            res.json({ error: false, data: chargers });
        }
        catch (error) {
            logger.error('Error fetching chargers', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async createCharger(req, res) {
        try {
            const { charger_id, name, location, connectors, site_id, tariff_id, 
            // Device Info
            vendor, model, serial_number, 
            // Security
            ocpp_password } = req.body;
            const existing = await shared_1.Charger.findOne({ charger_id });
            if (existing) {
                return res.status(400).json({ error: true, message: 'Charger ID already exists' });
            }
            // 1. Validate Connectors
            let finalConnectors = [];
            if (Array.isArray(connectors) && connectors.length > 0) {
                // Use provided connectors but sanitize
                finalConnectors = connectors.map((c, index) => ({
                    connector_id: c.connector_id || index + 1, // Auto-assign ID if missing
                    type: c.type || 'Type2',
                    max_power_kw: c.max_power_kw || 22.0,
                    status: 'Available'
                }));
            }
            else {
                // Default to 1 connector if none provided
                finalConnectors = [{
                        connector_id: 1,
                        type: 'Type2',
                        max_power_kw: 22.0,
                        status: 'Available'
                    }];
            }
            // 2. Security Defaults
            const finalPassword = ocpp_password || Math.random().toString(36).slice(-8); // Auto-gen password
            const charger = await shared_1.Charger.create({
                charger_id,
                name,
                location,
                site_id,
                tariff_id,
                connectors: finalConnectors,
                status: 'offline',
                // New Fields
                vendor,
                modelName: model,
                serial_number,
                ocpp_username: charger_id,
                ocpp_password: finalPassword
            });
            res.status(201).json({
                error: false,
                message: 'Charger created',
                data: charger,
                credentials: {
                    identity: charger_id,
                    password: finalPassword,
                    endpoint: `ws://YOUR_DOMAIN/ocpp/${charger_id}`
                }
            });
        }
        catch (error) {
            logger.error('Error creating charger', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async getChargerById(req, res) {
        try {
            const { id } = req.params;
            const charger = await shared_1.Charger.findOne({ charger_id: id });
            if (!charger)
                return res.status(404).json({ error: true, message: 'Charger not found' });
            res.json({ error: false, data: charger });
        }
        catch (error) {
            logger.error('Error fetching charger', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async updateCharger(req, res) {
        try {
            const { id } = req.params;
            const updates = req.body;
            if (updates.model) {
                updates.modelName = updates.model;
                delete updates.model;
            }
            const charger = await shared_1.Charger.findOneAndUpdate({ charger_id: id }, updates, { new: true });
            if (!charger)
                return res.status(404).json({ error: true, message: 'Charger not found' });
            res.json({ error: false, message: 'Charger updated', data: charger });
        }
        catch (error) {
            logger.error('Error updating charger', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async deleteCharger(req, res) {
        try {
            const { id } = req.params;
            const charger = await shared_1.Charger.findOneAndDelete({ charger_id: id });
            if (!charger)
                return res.status(404).json({ error: true, message: 'Charger not found' });
            res.json({ error: false, message: 'Charger deleted successfully' });
        }
        catch (error) {
            logger.error('Error deleting charger', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
}
exports.ChargerController = ChargerController;
//# sourceMappingURL=charger.controller.js.map