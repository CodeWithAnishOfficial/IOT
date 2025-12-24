import { Router, Request, Response } from 'express';
import { User, ChargingSession, Logger, RedisService } from '@ev-platform-v1/shared';
import { authMiddleware } from '../middlewares/auth.middleware';
import { InvoiceService } from '../services/invoice.service';

const router = Router();
const logger = new Logger('ProfileController');
const redis = RedisService.getInstance();

router.use(authMiddleware);

router.get('/me', async (req: Request, res: Response) => {
  try {
    // @ts-ignore
    const email = req.user.email_id;
    
    // Check cache
    const CACHE_KEY = `user:${email}:profile`;
    let user = await redis.get(CACHE_KEY);

    if (!user) {
        user = await User.findOne({ email_id: email });
        if (!user) return res.status(404).json({ error: true, message: 'User not found' });
        await redis.set(CACHE_KEY, user, 300); // Cache for 5 mins
    }
    
    res.json({ error: false, data: user });
  } catch (error: any) {
    logger.error('Error fetching profile', error);
    res.status(500).json({ error: true, message: error.message });
  }
});

router.put('/me', async (req: Request, res: Response) => {
  try {
    // @ts-ignore
    const email = req.user.email_id;
    const { username, phone_no } = req.body;
    
    const user = await User.findOneAndUpdate(
      { email_id: email },
      { $set: { username, phone_no, updated_at: new Date() } },
      { new: true }
    );
    
    // Invalidate cache
    const CACHE_KEY = `user:${email}:profile`;
    await redis.del(CACHE_KEY);
    
    res.json({ error: false, message: 'Profile updated', data: user });
  } catch (error: any) {
    logger.error('Error updating profile', error);
    res.status(500).json({ error: true, message: error.message });
  }
});

router.get('/sessions', async (req: Request, res: Response) => {
  try {
    // @ts-ignore
    const email = req.user.email_id;
    // Assuming user_id in ChargingSession matches email or some user ID.
    // In startTransaction handler we used idTag as user_id.
    // Ideally we should resolve user_id from tag, but for now querying by user_id field.
    
    const sessions = await ChargingSession.find({ user_id: email }).sort({ start_time: -1 });
    res.json({ error: false, data: sessions });
  } catch (error: any) {
    logger.error('Error fetching sessions', error);
    res.status(500).json({ error: true, message: error.message });
  }
});

router.post('/sessions/:id/invoice', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    // @ts-ignore
    const email = req.user.email_id;
    
    const session = await ChargingSession.findOne({ session_id: id });
    if (!session) return res.status(404).json({ error: true, message: 'Session not found' });
    
    const pdfBuffer = await InvoiceService.generateInvoice(session);
    await InvoiceService.sendInvoiceEmail(email, pdfBuffer, session);

    res.json({ error: false, message: 'Invoice sent to email' });
  } catch (error: any) {
    logger.error('Error sending invoice', error);
    res.status(500).json({ error: true, message: error.message });
  }
});

export default router;

