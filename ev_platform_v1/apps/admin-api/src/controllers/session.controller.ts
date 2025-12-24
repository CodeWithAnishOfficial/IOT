import { Request, Response } from 'express';
import { ChargingSession, Logger } from '@ev-platform-v1/shared';

const logger = new Logger('AdminSessionController');

export class AdminSessionController {
  
  static async getAllSessions(req: Request, res: Response) {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;
      const skip = (page - 1) * limit;

      const { user_id, charger_id, status, start_date, end_date } = req.query;
      
      const query: any = {};
      if (user_id) query.user_id = user_id;
      if (charger_id) query.charger_id = charger_id;
      if (status) query.status = status;
      if (start_date && end_date) {
        query.start_time = { $gte: new Date(start_date as string), $lte: new Date(end_date as string) };
      }

      const sessions = await ChargingSession.find(query)
        .sort({ start_time: -1 })
        .skip(skip)
        .limit(limit);

      const total = await ChargingSession.countDocuments(query);

      res.json({ 
        error: false, 
        data: sessions,
        pagination: {
            page,
            limit,
            total,
            pages: Math.ceil(total / limit)
        }
      });
    } catch (error: any) {
      logger.error('Error fetching sessions', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async getSessionDetails(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const session = await ChargingSession.findOne({ session_id: id });
      if (!session) return res.status(404).json({ error: true, message: 'Session not found' });
      res.json({ error: false, data: session });
    } catch (error: any) {
      res.status(500).json({ error: true, message: error.message });
    }
  }
}
