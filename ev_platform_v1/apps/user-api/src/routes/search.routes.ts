import { Router, Request, Response } from 'express';
import { ChargingStation, Logger, RedisService } from '@ev-platform-v1/shared';

const router = Router();
const logger = new Logger('SearchController');
const redis = RedisService.getInstance();

router.get('/nearby', async (req: Request, res: Response) => {
  try {
    const { lat, lng, radius = 5000 } = req.query; // Radius in meters
    
    if (!lat || !lng) {
      return res.status(400).json({ error: true, message: 'Lat and Lng required' });
    }

    // Since we don't have GeoJSON index set up in the schema yet, we'll do a basic filter or assume schema update
    // But for a robust solution, we should update the schema.
    // However, I can't easily update existing mongo index in this environment without access to DB shell.
    // Let's implement a Haversine formula filter in memory if dataset is small, or just basic query
    // Actually, let's just query all and filter in memory for this MVP since dataset is small.
    
    // Check Cache
    const CACHE_KEY = 'stations:online';
    let stations = await redis.get(CACHE_KEY);

    if (!stations) {
        stations = await ChargingStation.find({ status: 'online' }); // Only show online stations
        await redis.set(CACHE_KEY, stations, 60); // Cache for 60 seconds
    }
    
    // Simple distance calculation
    const nearby = stations.filter((station: any) => {
      if (!station.location || !station.location.lat || !station.location.lng) return false;
      
      const R = 6371e3; // metres
      const φ1 = parseFloat(lat as string) * Math.PI/180;
      const φ2 = station.location.lat * Math.PI/180;
      const Δφ = (station.location.lat - parseFloat(lat as string)) * Math.PI/180;
      const Δλ = (station.location.lng - parseFloat(lng as string)) * Math.PI/180;

      const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
              Math.cos(φ1) * Math.cos(φ2) *
              Math.sin(Δλ/2) * Math.sin(Δλ/2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
      const d = R * c;

      return d <= parseFloat(radius as string);
    });

    res.json({ error: false, data: nearby });
  } catch (error: any) {
    logger.error('Error searching stations', error);
    res.status(500).json({ error: true, message: error.message });
  }
});

export default router;
