"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChargingStationController = void 0;
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('ChargingStationController');
class ChargingStationController {
    static async getAllStations(req, res) {
        try {
            const stations = await shared_1.ChargingStation.find();
            res.json({ error: false, data: stations });
        }
        catch (error) {
            logger.error('Error fetching stations', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async createStation(req, res) {
        try {
            const { charger_id, name, location, connectors, site_id, tariff_id, 
            // Device Info
            vendor, model, serial_number, 
            // Security
            ocpp_password } = req.body;
            const existing = await shared_1.ChargingStation.findOne({ charger_id });
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
            const station = await shared_1.ChargingStation.create({
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
                message: 'Station created',
                data: station,
                credentials: {
                    identity: charger_id,
                    password: finalPassword,
                    endpoint: `ws://YOUR_DOMAIN/ocpp/${charger_id}`
                }
            });
        }
        catch (error) {
            logger.error('Error creating station', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async getStationById(req, res) {
        try {
            const { id } = req.params;
            const station = await shared_1.ChargingStation.findOne({ charger_id: id });
            if (!station)
                return res.status(404).json({ error: true, message: 'Station not found' });
            res.json({ error: false, data: station });
        }
        catch (error) {
            logger.error('Error fetching station', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async updateStation(req, res) {
        try {
            const { id } = req.params;
            const updates = req.body;
            if (updates.model) {
                updates.modelName = updates.model;
                delete updates.model;
            }
            const station = await shared_1.ChargingStation.findOneAndUpdate({ charger_id: id }, updates, { new: true });
            if (!station)
                return res.status(404).json({ error: true, message: 'Station not found' });
            res.json({ error: false, message: 'Station updated', data: station });
        }
        catch (error) {
            logger.error('Error updating station', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async deleteStation(req, res) {
        try {
            const { id } = req.params;
            const station = await shared_1.ChargingStation.findOneAndDelete({ charger_id: id });
            if (!station)
                return res.status(404).json({ error: true, message: 'Station not found' });
            res.json({ error: false, message: 'Station deleted successfully' });
        }
        catch (error) {
            logger.error('Error deleting station', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
}
exports.ChargingStationController = ChargingStationController;
//# sourceMappingURL=charging-station.controller.js.map