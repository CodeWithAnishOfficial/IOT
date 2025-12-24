import { Router, Request, Response } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import { SseService } from '../services/sse.service';

const router = Router();

router.get('/connect', authMiddleware, (req: Request, res: Response) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();

  // @ts-ignore
  const userId = req.user.email_id;
  SseService.addClient(res, userId);

  // Send initial ping
  res.write('event: connected\n');
  res.write(`data: ${JSON.stringify({ message: 'Connected to SSE' })}\n\n`);
});

export default router;
