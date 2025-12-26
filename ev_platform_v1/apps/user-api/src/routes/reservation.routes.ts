import { Router, Request, Response } from 'express';
import { Reservation, RedisService, Logger, ChargingStation } from '@ev-platform-v1/shared';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();
const logger = new Logger('ReservationController');
const redis = RedisService.getInstance();

router.use(authMiddleware);

// Route: POST /reservations/create
// Description: Create a new reservation for a connector
router.post('/create', async (req: Request, res: Response) => {
  try {
    const { charger_id, connector_id, expiry_minutes = 15 } = req.body;
    // @ts-ignore
    const userId = req.user.email_id;

    // Check if station exists and connector is available (naive check)
    const station = await ChargingStation.findOne({ charger_id });
    if (!station) return res.status(404).json({ error: true, message: 'Station not found' });

    // In production, we should check if there are overlapping reservations or if connector is currently charging.
    // For now, we trust the station to Reject if busy.

    const reservationId = Math.floor(Date.now() / 1000); // Simple ID
    const expiryDate = new Date(Date.now() + expiry_minutes * 60000);

    // Create Reservation Record
    const reservation = await Reservation.create({
      reservation_id: reservationId,
      charger_id,
      connector_id,
      user_id: userId,
      expiry_date: expiryDate,
      status: 'Pending'
    });

    // Send ReserveNow command
    // Payload for OCPP 1.6 ReserveNow: { connectorId, expiryDate, idTag, reservationId, parentIdTag? }
    const payload = {
        connectorId: connector_id,
        expiryDate: expiryDate.toISOString(),
        idTag: userId, // Using email as tag for now, ideally an RFID tag
        reservationId: reservationId
    };

    await redis.sendCommand(charger_id, 'ReserveNow', payload);

    res.json({ error: false, message: 'Reservation request sent', data: reservation });

  } catch (error: any) {
    logger.error('Error creating reservation', error);
    res.status(500).json({ error: true, message: error.message });
  }
});

// Route: GET /reservations/list
// Description: List all reservations for the current user
router.get('/list', async (req: Request, res: Response) => {
    try {
        // @ts-ignore
        const userId = req.user.email_id;
        const reservations = await Reservation.find({ user_id: userId }).sort({ created_at: -1 });
        res.json({ error: false, data: reservations });
    } catch (error: any) {
        res.status(500).json({ error: true, message: error.message });
    }
});

export default router;
