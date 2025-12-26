import { useState, useEffect, useRef } from 'react';
import { useTheme } from '@mui/material/styles';

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
  IconButton,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Tooltip,
  Stack,
  Typography,
  Grid,
  Divider
} from '@mui/material';

// icons
import { Edit, Trash, Add, Location, Eye, Map, Buildings, More, Gallery } from 'iconsax-reactjs';

// third-party
import { MapContainer, TileLayer, Marker, useMapEvents } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';

// project-imports
import MainCard from 'components/MainCard';
import SiteService from 'api/site';

// Fix Leaflet marker icon issue
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
});

// Map Click Component
function LocationMarker({ position, setPosition }) {
  const map = useMapEvents({
    click(e) {
      setPosition(e.latlng);
      map.flyTo(e.latlng, map.getZoom());
    },
  });

  return position === null ? null : (
    <Marker position={position}></Marker>
  );
}

export default function SitesList() {
  const theme = useTheme();
  const [sites, setSites] = useState([]);
  const [loading, setLoading] = useState(true);
  const [open, setOpen] = useState(false);
  const [viewOpen, setViewOpen] = useState(false);
  const [isEdit, setIsEdit] = useState(false);
  const [selectedSite, setSelectedSite] = useState(null);
  
  // Map State
  const [mapPosition, setMapPosition] = useState({ lat: 20.5937, lng: 78.9629 }); // Default to India

  // Form State
  const [formData, setFormData] = useState({
    name: '',
    address: '',
    city: '',
    state: '',
    country: '',
    zip_code: '',
    lat: '',
    lng: '',
    facilities: '',
    images: ''
  });

  useEffect(() => {
    fetchSites();
  }, []);

  const fetchSites = async () => {
    try {
      const response = await SiteService.getAllSites();
      if (!response.data.error) {
        setSites(response.data.data);
      }
    } catch (error) {
      console.error('Error fetching sites:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleOpen = (site = null) => {
    if (site) {
      setIsEdit(true);
      setSelectedSite(site);
      setFormData({
        name: site.name,
        address: site.address,
        city: site.city,
        state: site.state,
        country: site.country,
        zip_code: site.zip_code,
        lat: site.location?.lat || '',
        lng: site.location?.lng || '',
        facilities: site.facilities ? site.facilities.join(', ') : '',
        images: site.images ? site.images.join(', ') : ''
      });
      if (site.location?.lat && site.location?.lng) {
          setMapPosition({ lat: site.location.lat, lng: site.location.lng });
      }
    } else {
      setIsEdit(false);
      setSelectedSite(null);
      setFormData({
        name: '',
        address: '',
        city: '',
        state: '',
        country: '',
        zip_code: '',
        lat: '',
        lng: '',
        facilities: '',
        images: ''
      });
      setMapPosition({ lat: 20.5937, lng: 78.9629 });
    }
    setOpen(true);
  };

  const handleClose = () => {
    setOpen(false);
    setViewOpen(false);
  };

  const handleViewOpen = (site) => {
    setSelectedSite(site);
    setViewOpen(true);
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };
  
  const handleMapClick = (latlng) => {
      setMapPosition(latlng);
      setFormData((prev) => ({
          ...prev,
          lat: latlng.lat.toFixed(6),
          lng: latlng.lng.toFixed(6)
      }));
  };

  const handleFileUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const uploadData = new FormData();
    uploadData.append('image', file);

    try {
      const response = await SiteService.uploadImage(uploadData);
      if (!response.data.error) {
        const imageUrl = response.data.url;
        setFormData(prev => ({
            ...prev,
            images: prev.images ? `${prev.images}, ${imageUrl}` : imageUrl
        }));
      }
    } catch (error) {
      console.error('Error uploading image:', error);
      alert('Error uploading image');
    }
  };

  const handleSubmit = async () => {
    try {
      // Prepare payload with location object
      const payload = {
        name: formData.name,
        address: formData.address,
        city: formData.city,
        state: formData.state,
        country: formData.country,
        zip_code: formData.zip_code,
        facilities: formData.facilities ? formData.facilities.split(',').map(item => item.trim()).filter(Boolean) : [],
        images: formData.images ? formData.images.split(',').map(item => item.trim()).filter(Boolean) : [],
        location: {
          lat: parseFloat(formData.lat) || 0,
          lng: parseFloat(formData.lng) || 0
        }
      };

      if (isEdit) {
        await SiteService.updateSite(selectedSite._id, payload);
      } else {
        await SiteService.createSite(payload);
      }
      fetchSites();
      handleClose();
    } catch (error) {
      console.error('Error saving site:', error);
      alert(error.response?.data?.message || 'Error saving site');
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this site?')) {
      try {
        await SiteService.deleteSite(id);
        fetchSites();
      } catch (error) {
        console.error('Error deleting site:', error);
        alert(error.response?.data?.message || 'Error deleting site');
      }
    }
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <MainCard title="Sites" secondary={
      <Button variant="contained" startIcon={<Add />} onClick={() => handleOpen()}>
        Add Site
      </Button>
    }>
      <TableContainer component={Paper} sx={{ boxShadow: 'none', border: '1px solid', borderColor: 'divider' }}>
        <Table sx={{ minWidth: 650 }} aria-label="sites table">
          <TableHead>
            <TableRow>
              <TableCell>Name</TableCell>
              <TableCell>Location (Lat, Lng)</TableCell>
              <TableCell>Address</TableCell>
              <TableCell>City</TableCell>
              <TableCell>State</TableCell>
              <TableCell>Zip Code</TableCell>
              <TableCell align="right">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {sites.map((site, index) => (
              <TableRow key={site._id} sx={{ backgroundColor: index % 2 !== 0 ? theme.palette.secondary.lighter : 'inherit' }}>
                <TableCell>
                  <Stack direction="row" spacing={1.5} alignItems="center">
                    <Location size={18} variant="Bold" />
                    <Typography variant="subtitle1">{site.name}</Typography>
                  </Stack>
                </TableCell>
                <TableCell>
                  {site.location?.lat}, {site.location?.lng}
                </TableCell>
                <TableCell>{site.address}</TableCell>
                <TableCell>{site.city}</TableCell>
                <TableCell>{site.state}</TableCell>
                <TableCell>{site.zip_code}</TableCell>
                <TableCell align="right">
                  <Tooltip title="View Details">
                    <IconButton color="secondary" onClick={() => handleViewOpen(site)}>
                      <Eye variant="Bold" size={20}/>
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Edit">
                    <IconButton color="primary" onClick={() => handleOpen(site)}>
                      <Edit variant="Bold" size={20}/>
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Delete">
                    <IconButton color="error" onClick={() => handleDelete(site._id)}>
                      <Trash variant="Bold" size={20}/>
                    </IconButton>
                  </Tooltip>
                </TableCell>
              </TableRow>
            ))}
            {sites.length === 0 && (
              <TableRow>
                <TableCell colSpan={7} align="center">
                  No sites found
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Create/Edit Dialog */}
      <Dialog open={open} onClose={handleClose} maxWidth="md" fullWidth>
        <DialogTitle>{isEdit ? 'Edit Site' : 'Create Site'}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <Stack direction="row" spacing={2}>
                <Box sx={{ width: '50%' }}>
                     <Stack spacing={2}>
                        <TextField
                        name="name"
                        label="Site Name"
                        fullWidth
                        value={formData.name}
                        onChange={handleInputChange}
                        required
                        />
                        <Stack direction="row" spacing={2}>
                        <TextField
                            name="lat"
                            label="Latitude"
                            type="number"
                            fullWidth
                            value={formData.lat}
                            onChange={handleInputChange}
                            required
                        />
                        <TextField
                            name="lng"
                            label="Longitude"
                            type="number"
                            fullWidth
                            value={formData.lng}
                            onChange={handleInputChange}
                            required
                        />
                        </Stack>
                        <TextField
                        name="address"
                        label="Address"
                        fullWidth
                        multiline
                        rows={2}
                        value={formData.address}
                        onChange={handleInputChange}
                        />
                        <Stack direction="row" spacing={2}>
                        <TextField
                            name="city"
                            label="City"
                            fullWidth
                            value={formData.city}
                            onChange={handleInputChange}
                        />
                        <TextField
                            name="state"
                            label="State"
                            fullWidth
                            value={formData.state}
                            onChange={handleInputChange}
                        />
                        </Stack>
                        <Stack direction="row" spacing={2}>
                        <TextField
                            name="country"
                            label="Country"
                            fullWidth
                            value={formData.country}
                            onChange={handleInputChange}
                        />
                        <TextField
                            name="zip_code"
                            label="Zip Code"
                            fullWidth
                            value={formData.zip_code}
                            onChange={handleInputChange}
                        />
                        </Stack>
                        <TextField
                            name="facilities"
                            label="Facilities (comma separated)"
                            fullWidth
                            value={formData.facilities}
                            onChange={handleInputChange}
                            placeholder="e.g. Wifi, Cafe, Parking"
                        />
                        <Stack direction="row" spacing={1} alignItems="flex-start">
                            <TextField
                                name="images"
                                label="Image URLs"
                                fullWidth
                                multiline
                                rows={2}
                                value={formData.images}
                                onChange={handleInputChange}
                                placeholder="URLs separated by comma"
                            />
                            <Button variant="contained" component="label" sx={{ whiteSpace: 'nowrap' }}>
                                Upload
                                <input hidden accept="image/*" type="file" onChange={handleFileUpload} />
                            </Button>
                        </Stack>
                     </Stack>
                </Box>
                <Box sx={{ width: '50%', height: '400px', border: '1px solid #ccc' }}>
                     <MapContainer center={mapPosition} zoom={5} style={{ height: '100%', width: '100%' }}>
                        <TileLayer
                            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                        />
                        <LocationMarker position={mapPosition} setPosition={handleMapClick} />
                    </MapContainer>
                </Box>
            </Stack>
            
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose} color="secondary">Cancel</Button>
          <Button onClick={handleSubmit} variant="contained">
            {isEdit ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* View Details Dialog */}
      <Dialog open={viewOpen} onClose={handleClose} maxWidth="sm" fullWidth>
        <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Buildings size={24} variant="Bold" />
            Site Details
        </DialogTitle>
        <DialogContent dividers>
            {selectedSite && (
              <Grid container spacing={2}>
                <Grid item xs={12}>
                    <MainCard content={false} sx={{ p: 2 }}>
                         <Stack direction="row" spacing={2} alignItems="center">
                            <Box sx={{ width: 48, height: 48, borderRadius: '12px', bgcolor: 'primary.lighter', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <Location size={24} color="#333" variant="Bold" />
                            </Box>
                            <Stack>
                                <Typography variant="h5">{selectedSite.name}</Typography>
                                <Typography variant="caption" color="textSecondary">ID: {selectedSite._id}</Typography>
                            </Stack>
                        </Stack>
                    </MainCard>
                </Grid>

                <Grid item xs={12}>
                    <Typography variant="h6" sx={{ mb: 2 }}>Location Info</Typography>
                     <MainCard content={false}>
                        <Stack divider={<Divider />}>
                             <Stack direction="row" spacing={2} alignItems="center" sx={{ p: 2 }}>
                                <Map size={20} color="#666" />
                                <Box>
                                    <Typography variant="caption" color="textSecondary">Coordinates</Typography>
                                    <Typography variant="body1">Lat: {selectedSite.location?.lat}, Lng: {selectedSite.location?.lng}</Typography>
                                </Box>
                            </Stack>
                             <Stack direction="row" spacing={2} alignItems="center" sx={{ p: 2 }}>
                                <Buildings size={20} color="#666" />
                                <Box>
                                    <Typography variant="caption" color="textSecondary">Address</Typography>
                                    <Typography variant="body1">{selectedSite.address}</Typography>
                                    <Typography variant="body2" color="textSecondary">{selectedSite.city}, {selectedSite.state}, {selectedSite.country} - {selectedSite.zip_code}</Typography>
                                </Box>
                            </Stack>
                        </Stack>
                    </MainCard>
                </Grid>

                <Grid item xs={12}>
                     <Typography variant="h6" sx={{ mb: 2 }}>Amenities & Media</Typography>
                     <Grid container spacing={2}>
                        <Grid item xs={12}>
                            <MainCard content={false} sx={{ p: 2 }}>
                                <Stack spacing={1}>
                                    <Stack direction="row" spacing={1} alignItems="center">
                                        <More size={18} color="#666" />
                                        <Typography variant="caption" color="textSecondary">Facilities</Typography>
                                    </Stack>
                                    <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap>
                                        {selectedSite.facilities && selectedSite.facilities.length > 0 ? (
                                            selectedSite.facilities.map((fac, idx) => (
                                                <Chip key={idx} label={fac} size="small" variant="outlined" />
                                            ))
                                        ) : (
                                            <Typography variant="body2">None listed</Typography>
                                        )}
                                    </Stack>
                                </Stack>
                            </MainCard>
                        </Grid>
                     </Grid>
                </Grid>
              </Grid>
            )}
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose} variant="contained">Close</Button>
        </DialogActions>
      </Dialog>
    </MainCard>
  );
}
