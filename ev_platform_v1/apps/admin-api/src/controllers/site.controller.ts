import { Request, Response } from 'express';
import { Site, Logger, ChargingStation } from '@ev-platform-v1/shared';

const logger = new Logger('SiteController');

export class SiteController {
  
  static async createSite(req: Request, res: Response) {
    try {
      const site = await Site.create(req.body);
      res.status(201).json({ error: false, message: 'Site created', data: site });
    } catch (error: any) {
      logger.error('Error creating site', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async getAllSites(req: Request, res: Response) {
    try {
      const sites = await Site.find().sort({ created_at: -1 });
      res.json({ error: false, data: sites });
    } catch (error: any) {
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async getSiteById(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const site = await Site.findById(id);
      if (!site) return res.status(404).json({ error: true, message: 'Site not found' });
      
      // Optionally fetch all chargers at this site
      const chargers = await ChargingStation.find({ site_id: id });
      
      res.json({ error: false, data: { ...site.toObject(), chargers } });
    } catch (error: any) {
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async updateSite(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const site = await Site.findByIdAndUpdate(id, req.body, { new: true });
      if (!site) return res.status(404).json({ error: true, message: 'Site not found' });
      res.json({ error: false, message: 'Site updated', data: site });
    } catch (error: any) {
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async deleteSite(req: Request, res: Response) {
    try {
      const { id } = req.params;
      // Check if there are chargers linked
      const chargersCount = await ChargingStation.countDocuments({ site_id: id });
      if (chargersCount > 0) {
        return res.status(400).json({ error: true, message: `Cannot delete site. It has ${chargersCount} chargers linked.` });
      }

      await Site.findByIdAndDelete(id);
      res.json({ error: false, message: 'Site deleted' });
    } catch (error: any) {
      res.status(500).json({ error: true, message: error.message });
    }
  }
}
