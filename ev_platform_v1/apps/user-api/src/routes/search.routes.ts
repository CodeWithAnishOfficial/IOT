import { Router, Request, Response } from 'express';
import { ChargingStation, Logger, RedisService, Site } from '@ev-platform-v1/shared';

const router = Router();
const logger = new Logger('SearchController');
const redis = RedisService.getInstance();

// Route: GET /search/nearby
// Description: Find charging stations within a given radius
router.get('/nearby', async (req: Request, res: Response) => {
  try {
    const { lat: queryLat, lng: queryLng, radius = 5000 } = req.query; // Radius in meters
    
    if (!queryLat || !queryLng) {
      return res.status(400).json({ error: true, message: 'Lat and Lng required' });
    }

    // Since we don't have GeoJSON index set up in the schema yet, we'll do a basic filter or assume schema update
    // But for a robust solution, we should update the schema.
    // However, I can't easily update existing mongo index in this environment without access to DB shell.
    // Let's implement a Haversine formula filter in memory if dataset is small, or just basic query
    // Actually, let's just query all and filter in memory for this MVP since dataset is small.
    
    // Check Cache
    const CACHE_KEY = 'stations:all:populated';
    let stations = await redis.get(CACHE_KEY);

    if (!stations) {
        stations = await ChargingStation.find({}).populate('site_id'); // Show all stations and populate site
        await redis.set(CACHE_KEY, stations, 60); // Cache for 60 seconds
    }
    
    // Simple distance calculation
    const nearby = stations.filter((station: any) => {
      let lat = station.location?.lat;
      let lng = station.location?.lng;

      // Fallback to site location if station location is missing
      if ((!lat || !lng) && station.site_id && station.site_id.location) {
          lat = station.site_id.location.lat;
          lng = station.site_id.location.lng;
          
          // Patch the location into the station object for the frontend
          if (!station.location) station.location = {};
          station.location.lat = lat;
          station.location.lng = lng;
          if (station.site_id.address) station.location.address = station.site_id.address;
      }

      if (!lat || !lng) return false;
      
      const R = 6371e3; // metres
      const φ1 = parseFloat(queryLat as string) * Math.PI/180;
      const φ2 = lat * Math.PI/180;
      const Δφ = (lat - parseFloat(queryLat as string)) * Math.PI/180;
      const Δλ = (lng - parseFloat(queryLng as string)) * Math.PI/180;

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

// Route: GET /search/station/:id
// Description: Get details of a specific charging station
router.get('/station/:id', async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const station = await ChargingStation.findOne({ charger_id: id });
        if (!station) return res.status(404).json({ error: true, message: 'Station not found' });
        res.json({ error: false, data: station });
    } catch (error: any) {
        logger.error('Error fetching station details', error);
        res.status(500).json({ error: true, message: error.message });
    }
});

export default router;
