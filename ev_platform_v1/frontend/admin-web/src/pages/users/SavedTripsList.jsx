import { useState, useEffect, useRef } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useTheme } from '@mui/material/styles';
import { MapContainer, TileLayer, Marker, Popup, Polyline, Tooltip as LeafletTooltip, useMap } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';

// material-ui
import {
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  CircularProgress,
  Box,
  Typography,
  Stack,
  Button,
  IconButton,
  Tooltip,
  Grid,
  Divider,
  Dialog,
  DialogTitle,
  DialogContent
} from '@mui/material';

// icons
import { Map1, Location, Eye, ArrowRight, RouteSquare, BatteryCharging } from 'iconsax-reactjs';

// project-imports
import MainCard from 'components/MainCard';
import SavedTripService from 'api/savedTrips';

// Fix for default marker icon
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
});

// Component to fit map bounds
function MapBounds({ trip }) {
    const map = useMap();

    useEffect(() => {
        if (trip && trip.source && trip.destination) {
            const bounds = L.latLngBounds([
                [trip.source.lat, trip.source.lng],
                [trip.destination.lat, trip.destination.lng]
            ]);
            
            if (trip.stops && trip.stops.length > 0) {
                trip.stops.forEach(stop => {
                    if (stop.location && stop.location.lat && stop.location.lng) {
                        bounds.extend([stop.location.lat, stop.location.lng]);
                    }
                });
            }

            map.fitBounds(bounds, { padding: [50, 50] });
        }
    }, [trip, map]);

    return null;
}

export default function SavedTripsList() {
  const theme = useTheme();
  const location = useLocation();
  const navigate = useNavigate();
  const [trips, setTrips] = useState([]);
  const [loading, setLoading] = useState(true);
  const [userIdFilter, setUserIdFilter] = useState('');
  const [viewOpen, setViewOpen] = useState(false);
  const [selectedTrip, setSelectedTrip] = useState(null);
  
  useEffect(() => {
    // Parse query params
    const params = new URLSearchParams(location.search);
    const userId = params.get('user_id');
    
    if (userId) setUserIdFilter(userId);
    else setUserIdFilter('');
    
  }, [location.search]);

  useEffect(() => {
    fetchTrips();
  }, [userIdFilter]);

  const fetchTrips = async () => {
    try {
      setLoading(true);
      const filters = {};
      if (userIdFilter) {
          filters.user_id = userIdFilter;
      }
      
      const response = await SavedTripService.getAllSavedTrips(1, 50, filters);
      
      if (!response.data.error) {
        setTrips(response.data.data);
      }
    } catch (error) {
      console.error('Error fetching trips:', error);
    } finally {
        setLoading(false);
    }
  };

  const handleViewOpen = (trip) => {
    setSelectedTrip(trip);
    setViewOpen(true);
  };

  const handleClose = () => {
    setViewOpen(false);
  };

  const formatDate = (dateString) => {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleString();
  };

  const clearUserFilter = () => {
    setUserIdFilter('');
    navigate('/saved-trips');
  };

  if (loading && trips.length === 0) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
        <CircularProgress />
      </Box>
    );
  }

  const getTitle = () => {
    if (userIdFilter) return `Saved Trips for User: ${userIdFilter}`;
    return "Saved Trips";
  };

  return (
    <MainCard title={getTitle()} secondary={
      <Stack direction="row" spacing={2} alignItems="center">
        {userIdFilter && (
             <Button size="small" variant="outlined" color="error" onClick={clearUserFilter}>
                Clear Filter
             </Button>
        )}
      </Stack>
    }>
      <TableContainer component={Paper} sx={{ boxShadow: 'none', border: '1px solid', borderColor: 'divider' }}>
        <Table sx={{ minWidth: 650 }} aria-label="trips table">
          <TableHead>
            <TableRow>
              <TableCell>Trip Name</TableCell>
              <TableCell>User ID</TableCell>
              <TableCell>Source</TableCell>
              <TableCell>Destination</TableCell>
              <TableCell>Stops</TableCell>
              <TableCell>Created At</TableCell>
              <TableCell align="right">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {trips.map((trip, index) => (
              <TableRow key={trip.trip_id} sx={{ backgroundColor: index % 2 !== 0 ? theme.palette.secondary.lighter : 'inherit' }}>
                <TableCell>
                  <Stack direction="row" spacing={1} alignItems="center">
                    <RouteSquare size={18} color={theme.palette.primary.main}/>
                    <Typography variant="subtitle2">{trip.name}</Typography>
                  </Stack>
                </TableCell>
                <TableCell>{trip.user_id}</TableCell>
                <TableCell>
                    <Typography variant="body2" sx={{ maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                        {trip.source.address}
                    </Typography>
                </TableCell>
                <TableCell>
                    <Typography variant="body2" sx={{ maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                        {trip.destination.address}
                    </Typography>
                </TableCell>
                <TableCell>{trip.stops ? trip.stops.length : 0}</TableCell>
                <TableCell>{formatDate(trip.createdAt)}</TableCell>
                <TableCell align="right">
                  <Tooltip title="View Map & Details">
                    <IconButton color="secondary" onClick={() => handleViewOpen(trip)}>
                      <Map1 variant="Bold" size={20}/>
                    </IconButton>
                  </Tooltip>
                </TableCell>
              </TableRow>
            ))}
            {trips.length === 0 && (
              <TableRow>
                <TableCell colSpan={7} align="center">
                  No saved trips found
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* View Trip Dialog */}
      <Dialog open={viewOpen} onClose={handleClose} maxWidth="md" fullWidth>
        <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Map1 size={24} variant="Bold" />
            Trip Details: {selectedTrip?.name}
        </DialogTitle>
        <DialogContent dividers>
            {selectedTrip && (
              <Grid container spacing={2}>
                 <Grid item xs={12} sx={{ height: 400, mb: 2 }}>
                    <MapContainer center={[selectedTrip.source.lat, selectedTrip.source.lng]} zoom={10} style={{ height: '100%', width: '100%', borderRadius: 8 }}>
                        <TileLayer
                            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                        />
                        <MapBounds trip={selectedTrip} />
                        
                        {/* Source Marker */}
                        <Marker position={[selectedTrip.source.lat, selectedTrip.source.lng]}>
                            <Popup>
                                <strong>Source</strong><br/>
                                {selectedTrip.source.address}
                            </Popup>
                        </Marker>

                        {/* Destination Marker */}
                        <Marker position={[selectedTrip.destination.lat, selectedTrip.destination.lng]}>
                            <Popup>
                                <strong>Destination</strong><br/>
                                {selectedTrip.destination.address}
                            </Popup>
                        </Marker>

                        {/* Stops Markers */}
                        {selectedTrip.stops && selectedTrip.stops.map((stop, idx) => (
                            stop.location && stop.location.lat && (
                                <Marker key={idx} position={[stop.location.lat, stop.location.lng]}>
                                    <Popup>
                                        <strong>Stop {idx + 1}: {stop.name}</strong><br/>
                                        {stop.address}
                                    </Popup>
                                </Marker>
                            )
                        ))}

                        {/* Route Line (Direct line for visualization) */}
                        <Polyline 
                            positions={[
                                [selectedTrip.source.lat, selectedTrip.source.lng],
                                ...(selectedTrip.stops || []).map(s => [s.location.lat, s.location.lng]),
                                [selectedTrip.destination.lat, selectedTrip.destination.lng]
                            ]}
                            color="blue"
                        />
                    </MapContainer>
                 </Grid>

                 <Grid item xs={12}>
                    <MainCard content={false}>
                        <Stack divider={<Divider />}>
                             <Stack direction="row" spacing={2} alignItems="center" sx={{ p: 2 }}>
                                <Location size={20} color="green" variant="Bold" />
                                <Box>
                                    <Typography variant="caption" color="textSecondary">Source</Typography>
                                    <Typography variant="body1">{selectedTrip.source.address}</Typography>
                                </Box>
                            </Stack>
                            
                             {selectedTrip.stops && selectedTrip.stops.map((stop, index) => (
                                <Stack key={index} direction="row" spacing={2} alignItems="center" sx={{ p: 2, pl: 4 }}>
                                    <BatteryCharging size={18} color="orange" />
                                    <Box>
                                        <Typography variant="caption" color="textSecondary">Stop {index + 1} (Charger)</Typography>
                                        <Typography variant="body1">{stop.name}</Typography>
                                        <Typography variant="body2" color="textSecondary">{stop.address}</Typography>
                                    </Box>
                                </Stack>
                             ))}

                             <Stack direction="row" spacing={2} alignItems="center" sx={{ p: 2 }}>
                                <Location size={20} color="red" variant="Bold" />
                                <Box>
                                    <Typography variant="caption" color="textSecondary">Destination</Typography>
                                    <Typography variant="body1">{selectedTrip.destination.address}</Typography>
                                </Box>
                            </Stack>
                        </Stack>
                    </MainCard>
                 </Grid>
              </Grid>
            )}
        </DialogContent>
      </Dialog>
    </MainCard>
  );
}
