"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdminSupportController = void 0;
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('AdminSupportController');
class AdminSupportController {
    static async getAllTickets(req, res) {
        try {
            const { status } = req.query;
            const query = status ? { status } : {};
            const tickets = await shared_1.SupportTicket.find(query).sort({ created_at: -1 });
            res.json({ error: false, data: tickets });
        }
        catch (error) {
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async updateTicketStatus(req, res) {
        try {
            const { id } = req.params;
            const { status } = req.body;
            const ticket = await shared_1.SupportTicket.findOneAndUpdate({ ticket_id: id }, { status, updated_at: new Date() }, { new: true });
            if (!ticket)
                return res.status(404).json({ error: true, message: 'Ticket not found' });
            res.json({ error: false, message: 'Ticket updated', data: ticket });
        }
        catch (error) {
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async addReply(req, res) {
        try {
            const { id } = req.params;
            const { message } = req.body;
            const ticket = await shared_1.SupportTicket.findOneAndUpdate({ ticket_id: id }, {
                $push: { responses: { sender: 'admin', message, timestamp: new Date() } },
                $set: { updated_at: new Date() }
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
exports.AdminSupportController = AdminSupportController;
//# sourceMappingURL=support.controller.js.map