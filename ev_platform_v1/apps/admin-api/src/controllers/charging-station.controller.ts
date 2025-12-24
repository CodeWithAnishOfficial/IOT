import { Request, Response } from 'express';
import { ChargingStation, Logger } from '@ev-platform-v1/shared';

const logger = new Logger('ChargingStationController');

export class ChargingStationController {
  static async getAllStations(req: Request, res: Response) {
    try {
      const stations = await ChargingStation.find();
      res.json({ error: false, data: stations });
    } catch (error: any) {
      logger.error('Error fetching stations', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async createStation(req: Request, res: Response) {
    try {
      const { 
        charger_id, 
        name, 
        location, 
        connectors, 
        site_id,
        // Device Info
        vendor,
        model,
        serial_number,
        // Security
        ocpp_password
      } = req.body;
      
      const existing = await ChargingStation.findOne({ charger_id });
      if (existing) {
        return res.status(400).json({ error: true, message: 'Charger ID already exists' });
      }

      // 1. Validate Connectors
      let finalConnectors = [];
      if (Array.isArray(connectors) && connectors.length > 0) {
        // Use provided connectors but sanitize
        finalConnectors = connectors.map((c: any, index: number) => ({
            connector_id: c.connector_id || index + 1, // Auto-assign ID if missing
            type: c.type || 'Type2',
            max_power_kw: c.max_power_kw || 22.0,
            status: 'Available'
        }));
      } else {
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

      const station = await ChargingStation.create({
        charger_id,
        name,
        location,
        site_id, 
        connectors: finalConnectors,
        status: 'offline',
        // New Fields
        vendor,
        model,
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
    } catch (error: any) {
      logger.error('Error creating station', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async getStationById(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const station = await ChargingStation.findOne({ charger_id: id });
      if (!station) return res.status(404).json({ error: true, message: 'Station not found' });
      
      res.json({ error: false, data: station });
    } catch (error: any) {
      logger.error('Error fetching station', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async updateStation(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const updates = req.body;
      
      const station = await ChargingStation.findOneAndUpdate({ charger_id: id }, updates, { new: true });
      if (!station) return res.status(404).json({ error: true, message: 'Station not found' });

      res.json({ error: false, message: 'Station updated', data: station });
    } catch (error: any) {
      logger.error('Error updating station', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }
}
