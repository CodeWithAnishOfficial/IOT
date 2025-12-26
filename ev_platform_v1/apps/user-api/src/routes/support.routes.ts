import { Router } from 'express';
import { SupportController } from '../controllers/support.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

router.use(authMiddleware);

// Route: POST /support/create
// Description: Create a new support ticket
router.post('/create', SupportController.createTicket);

// Route: GET /support/list
// Description: Get all tickets created by the user
router.get('/list', SupportController.getMyTickets);

// Route: POST /support/:id/reply
// Description: Add a reply to a support ticket
router.post('/:id/reply', SupportController.addReply);

export default router;
