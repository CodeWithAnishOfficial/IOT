import { Request, Response } from 'express';
import SavedTrip from '../models/SavedTrip';
import { Logger } from '@ev-platform-v1/shared';

const logger = new Logger('AdminSavedTripController');

export class AdminSavedTripController {

    static async getAllSavedTrips(req: Request, res: Response) {
        try {
            const page = parseInt(req.query.page as string) || 1;
            const limit = parseInt(req.query.limit as string) || 20;
            const skip = (page - 1) * limit;

            const { user_id, trip_id } = req.query;

            const query: any = {};
            if (user_id) {
                const numId = Number(user_id);
                if (!isNaN(numId)) {
                    query.user_id = { $in: [user_id, numId] };
                } else {
                    query.user_id = user_id;
                }
            }
            if (trip_id) query.trip_id = trip_id;

            const trips = await SavedTrip.find(query)
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limit);

            const total = await SavedTrip.countDocuments(query);

            res.json({
                error: false,
                data: trips,
                pagination: {
                    page,
                    limit,
                    total,
                    pages: Math.ceil(total / limit)
                }
            });
        } catch (error: any) {
            logger.error('Error fetching saved trips', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }

    static async getSavedTripDetails(req: Request, res: Response) {
        try {
            const { id } = req.params;
            // id could be trip_id (number) or _id (string)
            const numId = Number(id);
            const query = !isNaN(numId) ? { trip_id: numId } : { _id: id };

            const trip = await SavedTrip.findOne(query);
            if (!trip) return res.status(404).json({ error: true, message: 'Trip not found' });
            res.json({ error: false, data: trip });
        } catch (error: any) {
            logger.error('Error fetching saved trip details', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
}
