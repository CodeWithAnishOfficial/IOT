import { Request, Response } from 'express';
import { Tariff, Logger, ChargingStation } from '@ev-platform-v1/shared';

const logger = new Logger('TariffController');

export class TariffController {
  
  static async createTariff(req: Request, res: Response) {
    try {
      const tariff = await Tariff.create(req.body);
      res.status(201).json({ error: false, message: 'Tariff created', data: tariff });
    } catch (error: any) {
      logger.error('Error creating tariff', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async getAllTariffs(req: Request, res: Response) {
    try {
      const tariffs = await Tariff.find().sort({ created_at: -1 });
      res.json({ error: false, data: tariffs });
    } catch (error: any) {
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async updateTariff(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const tariff = await Tariff.findByIdAndUpdate(id, req.body, { new: true });
      if (!tariff) return res.status(404).json({ error: true, message: 'Tariff not found' });
      res.json({ error: false, message: 'Tariff updated', data: tariff });
    } catch (error: any) {
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async deleteTariff(req: Request, res: Response) {
    try {
      const { id } = req.params;
      
      const stationsCount = await ChargingStation.countDocuments({ tariff_id: id });
      if (stationsCount > 0) {
        return res.status(400).json({ error: true, message: `Cannot delete tariff. It is assigned to ${stationsCount} stations.` });
      }

      await Tariff.findByIdAndDelete(id);
      res.json({ error: false, message: 'Tariff deleted' });
    } catch (error: any) {
      res.status(500).json({ error: true, message: error.message });
    }
  }
}
