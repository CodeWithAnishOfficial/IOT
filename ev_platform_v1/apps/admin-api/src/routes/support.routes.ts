import { Router } from 'express';
import { AdminSupportController } from '../controllers/support.controller';

const router = Router();

router.get('/', AdminSupportController.getAllTickets);
router.put('/:id/status', AdminSupportController.updateTicketStatus);
router.post('/:id/reply', AdminSupportController.addReply);

export default router;
