import { Router } from 'express';
import { AdminSessionController } from '../controllers/session.controller';

const router = Router();

router.get('/', AdminSessionController.getAllSessions);
router.get('/:id', AdminSessionController.getSessionDetails);

export default router;
