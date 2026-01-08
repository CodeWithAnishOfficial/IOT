import { Router, Request, Response } from 'express';
import SavedTrip from '../models/SavedTrip';
import { authMiddleware } from '../middlewares/auth.middleware';
import { Logger } from '@ev-platform-v1/shared';

const router = Router();
const logger = new Logger('SavedTripsController');

// Route: POST /saved-trips
// Description: Save a new trip
router.post('/', authMiddleware, async (req: Request, res: Response) => {
  try {
    // @ts-ignore
    const user_id = req.user?.user_id;
    const { name, source, destination, stops } = req.body;

    if (!name || !source || !destination) {
      return res.status(400).json({ error: true, message: 'Name, source, and destination are required' });
    }

    const trip_id = Math.floor(Date.now() / 1000); // Generate simple numeric ID

    const newTrip = await SavedTrip.create({
      trip_id,
      user_id: Number(user_id),
      name,
      source,
      destination,
      stops: stops || []
    });

    res.json({ error: false, message: 'Trip saved successfully', data: newTrip });
  } catch (error: any) {
    logger.error('Error saving trip', error);
    res.status(500).json({ error: true, message: error.message });
  }
});

// Route: GET /saved-trips
// Description: Get all saved trips for the user
router.get('/', authMiddleware, async (req: Request, res: Response) => {
  try {
    // @ts-ignore
    const user_id = req.user?.user_id;

    const trips = await SavedTrip.find({ user_id: Number(user_id) }).sort({ createdAt: -1 });

    res.json({ error: false, data: trips });
  } catch (error: any) {
    logger.error('Error fetching saved trips', error);
    res.status(500).json({ error: true, message: error.message });
  }
});

// Route: DELETE /saved-trips/:id
// Description: Delete a saved trip
router.delete('/:id', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    // @ts-ignore
    const user_id = req.user?.user_id;

    // Try deleting by numeric trip_id first (if id is numeric)
    let trip;
    if (!isNaN(Number(id))) {
       trip = await SavedTrip.findOneAndDelete({ trip_id: Number(id), user_id: Number(user_id) });
    }
    
    // If not found or id wasn't numeric, try _id
    if (!trip) {
       trip = await SavedTrip.findOneAndDelete({ _id: id, user_id: Number(user_id) });
    }

    if (!trip) {
      return res.status(404).json({ error: true, message: 'Trip not found or unauthorized' });
    }

    res.json({ error: false, message: 'Trip deleted successfully' });
  } catch (error: any) {
    logger.error('Error deleting trip', error);
    res.status(500).json({ error: true, message: error.message });
  }
});

export default router;
