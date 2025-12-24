import { Request, Response } from 'express';
import { SupportTicket, Logger } from '@ev-platform-v1/shared';

const logger = new Logger('AdminSupportController');

export class AdminSupportController {
  
  static async getAllTickets(req: Request, res: Response) {
    try {
      const { status } = req.query;
      const query = status ? { status } : {};
      
      const tickets = await SupportTicket.find(query).sort({ created_at: -1 });
      res.json({ error: false, data: tickets });
    } catch (error: any) {
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async updateTicketStatus(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { status } = req.body;
      
      const ticket = await SupportTicket.findOneAndUpdate(
        { ticket_id: id },
        { status, updated_at: new Date() },
        { new: true }
      );
      
      if (!ticket) return res.status(404).json({ error: true, message: 'Ticket not found' });
      res.json({ error: false, message: 'Ticket updated', data: ticket });
    } catch (error: any) {
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async addReply(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { message } = req.body;

      const ticket = await SupportTicket.findOneAndUpdate(
        { ticket_id: id },
        { 
            $push: { responses: { sender: 'admin', message, timestamp: new Date() } },
            $set: { updated_at: new Date() }
        },
        { new: true }
      );

      if (!ticket) return res.status(404).json({ error: true, message: 'Ticket not found' });

      res.json({ error: false, message: 'Reply added', data: ticket });
    } catch (error: any) {
      res.status(500).json({ error: true, message: error.message });
    }
  }
}
