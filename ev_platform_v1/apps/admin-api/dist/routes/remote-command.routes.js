"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const shared_1 = require("@ev-platform-v1/shared");
const router = (0, express_1.Router)();
const logger = new shared_1.Logger('RemoteCommandController');
const redis = shared_1.RedisService.getInstance();
// Helper to send commands
const sendCommand = async (req, res) => {
    try {
        const { id } = req.params;
        const { command, payload } = req.body;
        // Command validation
        const validCommands = ['RemoteStartTransaction', 'RemoteStopTransaction', 'UnlockConnector', 'Reset', 'GetConfiguration', 'ChangeConfiguration'];
        if (!validCommands.includes(command)) {
            return res.status(400).json({ error: true, message: 'Invalid command' });
        }
        await redis.sendCommand(id, command, payload || {});
        res.json({ error: false, message: `Command ${command} sent to ${id}` });
    }
    catch (error) {
        logger.error('Error sending remote command', error);
        res.status(500).json({ error: true, message: error.message });
    }
};
// Route: POST /remote-commands/:id/send
// Description: Send a generic OCPP command to a charger
router.post('/:id/send', sendCommand);
// Convenience routes
// Route: POST /remote-commands/:id/start-transaction
// Description: Remote start a transaction
router.post('/:id/start-transaction', (req, res) => {
    req.body.command = 'RemoteStartTransaction';
    sendCommand(req, res);
});
// Route: POST /remote-commands/:id/stop-transaction
// Description: Remote stop a transaction
router.post('/:id/stop-transaction', (req, res) => {
    req.body.command = 'RemoteStopTransaction';
    sendCommand(req, res);
});
// Route: POST /remote-commands/:id/unlock-connector
// Description: Unlock a connector
router.post('/:id/unlock-connector', (req, res) => {
    req.body.command = 'UnlockConnector';
    sendCommand(req, res);
});
// Route: POST /remote-commands/:id/reset
// Description: Reset a charger (Soft or Hard)
router.post('/:id/reset', (req, res) => {
    req.body.command = 'Reset';
    req.body.payload = { type: req.body.type || 'Soft' }; // Hard or Soft reset
    sendCommand(req, res);
});
exports.default = router;
//# sourceMappingURL=remote-command.routes.js.map