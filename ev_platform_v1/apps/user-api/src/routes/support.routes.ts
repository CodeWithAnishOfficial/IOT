import { Router } from 'express';
import { SupportController } from '../controllers/support.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

router.use(authMiddleware);

router.post('/', SupportController.createTicket);
router.get('/', SupportController.getMyTickets);
router.post('/:id/reply', SupportController.addReply);

export default router;
