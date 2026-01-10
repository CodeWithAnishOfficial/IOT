"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SupportController = void 0;
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('SupportController');
class SupportController {
    static async createTicket(req, res) {
        try {
            // @ts-ignore
            const userId = req.user.email_id;
            const { subject, description, priority, category } = req.body;
            const ticketId = 'TKT-' + Math.floor(100000 + Math.random() * 900000);
            const ticket = await shared_1.SupportTicket.create({
                ticket_id: ticketId,
                user_id: userId,
                subject,
                description,
                priority,
                category,
                status: 'Open',
                responses: [{
                        sender: 'user',
                        message: description,
                        timestamp: new Date()
                    }]
            });
            res.status(201).json({ error: false, message: 'Ticket created', data: ticket });
        }
        catch (error) {
            logger.error('Error creating ticket', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async getMyTickets(req, res) {
        try {
            // @ts-ignore
            const userId = req.user.email_id;
            const tickets = await shared_1.SupportTicket.find({ user_id: userId }).sort({ created_at: -1 });
            res.json({ error: false, data: tickets });
        }
        catch (error) {
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async addReply(req, res) {
        try {
            const { id } = req.params;
            // @ts-ignore
            const userId = req.user.email_id;
            const { message } = req.body;
            const ticket = await shared_1.SupportTicket.findOneAndUpdate({ ticket_id: id, user_id: userId }, {
                $push: { responses: { sender: 'user', message, timestamp: new Date() } },
                $set: { updated_at: new Date(), status: 'Open' } // Re-open if closed? Maybe.
            }, { new: true });
            if (!ticket)
                return res.status(404).json({ error: true, message: 'Ticket not found' });
            res.json({ error: false, message: 'Reply added', data: ticket });
        }
        catch (error) {
            res.status(500).json({ error: true, message: error.message });
        }
    }
}
exports.SupportController = SupportController;
//# sourceMappingURL=support.controller.js.map