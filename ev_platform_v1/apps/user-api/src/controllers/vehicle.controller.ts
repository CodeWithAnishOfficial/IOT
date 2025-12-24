import { Request, Response } from 'express';
import { Vehicle, Logger } from '@ev-platform-v1/shared';

const logger = new Logger('VehicleController');

export class VehicleController {
  
  static async addVehicle(req: Request, res: Response) {
    try {
      // @ts-ignore
      const userId = req.user.email_id;
      const { make, model, year, vin, plate_no, connector_type } = req.body;

      const vehicle = await Vehicle.create({
        user_id: userId,
        make,
        model,
        year,
        vin,
        plate_no,
        connector_type
      });

      res.status(201).json({ error: false, message: 'Vehicle added', data: vehicle });
    } catch (error: any) {
      logger.error('Error adding vehicle', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async getVehicles(req: Request, res: Response) {
    try {
      // @ts-ignore
      const userId = req.user.email_id;
      const vehicles = await Vehicle.find({ user_id: userId });
      res.json({ error: false, data: vehicles });
    } catch (error: any) {
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async deleteVehicle(req: Request, res: Response) {
    try {
      const { id } = req.params;
      // @ts-ignore
      const userId = req.user.email_id;
      await Vehicle.findOneAndDelete({ _id: id, user_id: userId });
      res.json({ error: false, message: 'Vehicle deleted' });
    } catch (error: any) {
      res.status(500).json({ error: true, message: error.message });
    }
  }
}
