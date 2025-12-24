import { Router } from 'express';
import { Request, Response } from 'express';
import { Logger, RedisService } from '@ev-platform-v1/shared';

const router = Router();
const logger = new Logger('RemoteCommandController');
const redis = RedisService.getInstance();

// Helper to send commands
const sendCommand = async (req: Request, res: Response) => {
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
  } catch (error: any) {
    logger.error('Error sending remote command', error);
    res.status(500).json({ error: true, message: error.message });
  }
};

router.post('/:id/command', sendCommand);

// Convenience routes
router.post('/:id/remote-start', (req, res) => {
  req.body.command = 'RemoteStartTransaction';
  sendCommand(req, res);
});

router.post('/:id/remote-stop', (req, res) => {
  req.body.command = 'RemoteStopTransaction';
  sendCommand(req, res);
});

router.post('/:id/unlock', (req, res) => {
  req.body.command = 'UnlockConnector';
  sendCommand(req, res);
});

router.post('/:id/reset', (req, res) => {
  req.body.command = 'Reset';
  req.body.payload = { type: req.body.type || 'Soft' }; // Hard or Soft reset
  sendCommand(req, res);
});

export default router;
