"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChargingController = void 0;
const shared_1 = require("@ev-platform-v1/shared");
const charging_service_1 = require("../services/charging.service");
const payment_service_1 = require("../services/payment.service");
const invoice_service_1 = require("../services/invoice.service");
const uuid_1 = require("uuid");
const logger = new shared_1.Logger('ChargingController');
const paymentService = new payment_service_1.PaymentService();
class ChargingController {
    static async getActiveSession(req, res) {
        try {
            // @ts-ignore
            const userId = req.user?.email_id;
            const session = await charging_service_1.ChargingService.getActiveSession(userId);
            if (session) {
                res.json({
                    error: false,
                    data: session
                });
            }
            else {
                res.json({
                    error: false,
                    data: null,
                    message: 'No active session found'
                });
            }
        }
        catch (error) {
            logger.error('Error fetching active session', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async getHistory(req, res) {
        try {
            // @ts-ignore
            const userId = req.user?.email_id;
            const history = await charging_service_1.ChargingService.getHistory(userId);
            res.json({
                error: false,
                data: history
            });
        }
        catch (error) {
            logger.error('Error fetching history', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async downloadInvoice(req, res) {
        try {
            // @ts-ignore
            const userId = req.user?.email_id;
            const { session_id } = req.params;
            if (!session_id) {
                return res.status(400).json({ error: true, message: 'Session ID required' });
            }
            const session = await charging_service_1.ChargingService.getSessionDetails(userId, session_id);
            const pdfBuffer = await invoice_service_1.InvoiceService.generateInvoice(session);
            res.set({
                'Content-Type': 'application/pdf',
                'Content-Disposition': `attachment; filename=invoice-${session_id}.pdf`,
                'Content-Length': pdfBuffer.length
            });
            res.send(pdfBuffer);
        }
        catch (error) {
            logger.error('Error generating invoice', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async initiatePayment(req, res) {
        try {
            const { amount } = req.body;
            if (!amount) {
                return res.status(400).json({ error: true, message: 'Amount is required' });
            }
            const receiptId = `chg_${(0, uuid_1.v4)()}`;
            const order = await paymentService.createOrder(Number(amount), receiptId);
            res.json({
                error: false,
                message: 'Order created',
                data: order
            });
        }
        catch (error) {
            logger.error('Error initiating payment', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async start(req, res) {
        try {
            // @ts-ignore
            const userId = req.user?.email_id;
            const { station_id, connector_id, amount, payment_details } = req.body;
            if (!station_id || !connector_id || !amount) {
                return res.status(400).json({ error: true, message: 'Missing required fields' });
            }
            const result = await charging_service_1.ChargingService.startSession(userId, station_id, connector_id, Number(amount), payment_details // Optional: { orderId, paymentId, signature }
            );
            res.json({
                error: false,
                message: 'Charging initiated',
                data: result
            });
        }
        catch (error) {
            logger.error('Error in start charging', error);
            res.status(500).json({
                error: true,
                message: error.message || 'Failed to start charging session'
            });
        }
    }
    static async stop(req, res) {
        try {
            // @ts-ignore
            const userId = req.user?.email_id;
            const { session_id } = req.body;
            if (!session_id) {
                return res.status(400).json({ error: true, message: 'Missing session_id' });
            }
            const result = await charging_service_1.ChargingService.stopSession(userId, session_id);
            res.json({
                error: false,
                message: 'Stop command initiated',
                data: result
            });
        }
        catch (error) {
            logger.error('Error in stop charging', error);
            res.status(500).json({
                error: true,
                message: error.message || 'Failed to stop charging session'
            });
        }
    }
    static async checkStatus(req, res) {
        try {
            // @ts-ignore
            const userId = req.user?.email_id;
            const { station_id, connector_id } = req.query;
            if (!station_id || !connector_id) {
                return res.status(400).json({ error: true, message: 'Missing station_id or connector_id' });
            }
            const result = await charging_service_1.ChargingService.checkConnectorStatus(String(station_id), Number(connector_id), userId);
            res.json({
                error: false,
                message: 'Connector is available',
                data: result
            });
        }
        catch (error) {
            // Don't log as error if it's just a validation failure
            logger.info(`Check status failed: ${error.message}`);
            res.status(400).json({
                error: true,
                message: error.message
            });
        }
    }
    static async releaseLock(req, res) {
        try {
            // @ts-ignore
            const userId = req.user?.email_id;
            const { station_id, connector_id } = req.body; // Use body for POST
            if (!station_id || !connector_id) {
                return res.status(400).json({ error: true, message: 'Missing station_id or connector_id' });
            }
            const result = await charging_service_1.ChargingService.releaseLock(String(station_id), Number(connector_id), userId);
            res.json({
                error: false,
                message: 'Lock release requested',
                data: result
            });
        }
        catch (error) {
            logger.error('Error releasing lock', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
}
exports.ChargingController = ChargingController;
//# sourceMappingURL=charging.controller.js.map