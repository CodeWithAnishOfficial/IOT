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
    const nearby = stations.map((station: any) => {
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

      if (!lat || !lng) return null;
      
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

      // Return enhanced object
      const sObj = station.toObject ? station.toObject() : station;
      return { ...sObj, distance: d / 1000 }; // km
    }).filter((s: any) => s !== null && (s.distance * 1000) <= parseFloat(radius as string));

    // Sort by distance (ascending)
    nearby.sort((a: any, b: any) => a.distance - b.distance);

    res.json({ error: false, data: nearby });
  } catch (error: any) {
    logger.error('Error searching stations', error);
    res.status(500).json({ error: true, message: error.message });
  }
});

// Route: POST /search/route
// Description: Find charging stations along a route (polyline) within a buffer distance
router.post('/route', async (req: Request, res: Response) => {
  try {
    const { routePoints, bufferDistance = 1000 } = req.body; // buffer in meters

    if (!routePoints || !Array.isArray(routePoints) || routePoints.length < 2) {
      return res.status(400).json({ error: true, message: 'Valid routePoints array required' });
    }

    // 1. Fetch all stations (Reuse cache logic)
    const CACHE_KEY = 'stations:all:populated';
    let stations = await redis.get(CACHE_KEY);

    if (!stations) {
        stations = await ChargingStation.find({}).populate('site_id');
        await redis.set(CACHE_KEY, stations, 60);
    }

    // 2. Filter stations along the route
    const nearby = stations.filter((station: any) => {
      let lat = station.location?.lat;
      let lng = station.location?.lng;

      // Fallback to site location logic (same as /nearby)
      if ((!lat || !lng) && station.site_id && station.site_id.location) {
          lat = station.site_id.location.lat;
          lng = station.site_id.location.lng;
          
          if (!station.location) station.location = {};
          station.location.lat = lat;
          station.location.lng = lng;
          if (station.site_id.address) station.location.address = station.site_id.address;
      }

      if (!lat || !lng) return false;

      // Check distance to polyline
      return isPointNearPolyline({ lat, lng }, routePoints, bufferDistance);
    });

    res.json({ error: false, data: nearby });
  } catch (error: any) {
    logger.error('Error searching stations on route', error);
    res.status(500).json({ error: true, message: error.message });
  }
});

// Helper: Calculate distance from point to line segment
function getDistanceFromPointToLine(point: {lat: number, lng: number}, lineStart: {lat: number, lng: number}, lineEnd: {lat: number, lng: number}): number {
  const R = 6371e3; // Earth radius in meters

  // Convert to Cartesian coordinates (approximate for small distances)
  // Or better, use cross-track distance formula on sphere
  // For simplicity and performance on small segments, we can use a flat-earth approximation for the segment projection
  // followed by Haversine for the actual distance.
  
  // However, Haversine from point to closest point on segment is best.
  // Let's use a simplified approach:
  // 1. Check distance to start and end points
  // 2. Check perpendicular distance if projection falls on segment
  
  // Implementation of cross-track distance would be ideal but complex.
  // Let's use a practical geometric approach converting lat/lng to meters (approx)
  
  const lat1 = lineStart.lat;
  const lng1 = lineStart.lng;
  const lat2 = lineEnd.lat;
  const lng2 = lineEnd.lng;
  const lat0 = point.lat;
  const lng0 = point.lng;

  // Project point onto line (parameter t)
  // x = lng, y = lat (roughly)
  // Adjust lng by cos(lat) to account for longitude shrinking
  const latAvg = (lat1 + lat2 + lat0) / 3 * (Math.PI / 180);
  const cosLat = Math.cos(latAvg);

  const x0 = lng0 * cosLat;
  const y0 = lat0;
  const x1 = lng1 * cosLat;
  const y1 = lat1;
  const x2 = lng2 * cosLat;
  const y2 = lat2;

  const dx = x2 - x1;
  const dy = y2 - y1;
  const lenSq = dx * dx + dy * dy;

  let t = lenSq === 0 ? -1 : ((x0 - x1) * dx + (y0 - y1) * dy) / lenSq;
  
  // Clamp t to segment [0, 1]
  t = Math.max(0, Math.min(1, t));

  // Closest point on segment
  const closestX = x1 + t * dx;
  const closestY = y1 + t * dy;

  // Convert back to lat/lng
  const closestLng = closestX / cosLat;
  const closestLat = closestY;

  // Calculate Haversine distance between point and closest point
  return getHaversineDistance(lat0, lng0, closestLat, closestLng);
}

function getHaversineDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371e3;
  const φ1 = lat1 * Math.PI/180;
  const φ2 = lat2 * Math.PI/180;
  const Δφ = (lat2 - lat1) * Math.PI/180;
  const Δλ = (lng2 - lng1) * Math.PI/180;

  const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
            Math.cos(φ1) * Math.cos(φ2) *
            Math.sin(Δλ/2) * Math.sin(Δλ/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}

function isPointNearPolyline(point: {lat: number, lng: number}, polyline: any[], threshold: number): boolean {
  // Optimization: Pre-check bounding box of point vs polyline segment
  // But given JS speed, direct calc might be fine for < 1000 points
  
  for (let i = 0; i < polyline.length - 1; i++) {
    const start = polyline[i];
    const end = polyline[i+1];
    
    // Quick bounding box check for the segment (with buffer)
    // 1 degree lat ~ 111km. 1km ~ 0.01 deg
    const bufferDeg = 0.02; // generous buffer
    const minLat = Math.min(start.lat, end.lat) - bufferDeg;
    const maxLat = Math.max(start.lat, end.lat) + bufferDeg;
    const minLng = Math.min(start.lng, end.lng) - bufferDeg;
    const maxLng = Math.max(start.lng, end.lng) + bufferDeg;

    if (point.lat < minLat || point.lat > maxLat || point.lng < minLng || point.lng > maxLng) {
      continue; 
    }

    const dist = getDistanceFromPointToLine(point, start, end);
    if (dist <= threshold) {
      return true;
    }
  }
  return false;
}

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
