import { useState, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
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
  Chip,
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
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Typography,
  Grid,
  Divider
} from '@mui/material';

// icons
import { Edit, Trash, Add, Convert3DCube, Eye, Box1, Cpu, Electricity, Barcode, Wifi, Location } from 'iconsax-reactjs';

// project-imports
import MainCard from 'components/MainCard';
import StationService from 'api/station';
import SiteService from 'api/site';

export default function StationsList() {
  const theme = useTheme();
  const location = useLocation();
  const [stations, setStations] = useState([]);
  const [sites, setSites] = useState([]);
  const [loading, setLoading] = useState(true);
  const [open, setOpen] = useState(false);
  const [viewOpen, setViewOpen] = useState(false);
  const [isEdit, setIsEdit] = useState(false);
  const [selectedStation, setSelectedStation] = useState(null);

  // Check for navigation state to open modal
  useEffect(() => {
    if (location.state?.openAdd) {
        handleOpen();
        // Clear state to prevent reopening on refresh (optional, but React Router handles this well usually)
        window.history.replaceState({}, document.title);
    }
  }, [location]);

  // Form State
  const [formData, setFormData] = useState({
    charger_id: '',
    name: '',
    site_id: '',
    vendor: '',
    model: '', // mapped to modelName in backend
    serial_number: '',
    ocpp_password: '',
    connectors: [{ type: 'Type2', max_power_kw: 22.0 }] // Simple default for now
  });

  useEffect(() => {
    Promise.all([
      fetchStations(),
      fetchSites()
    ]).finally(() => setLoading(false));
  }, []);

  const fetchStations = async () => {
    try {
      const response = await StationService.getAllStations();
      if (!response.data.error) {
        setStations(response.data.data);
      }
    } catch (error) {
      console.error('Error fetching stations:', error);
    }
  };

  const fetchSites = async () => {
    try {
      const response = await SiteService.getAllSites();
      if (!response.data.error) {
        setSites(response.data.data);
      }
    } catch (error) {
      console.error('Error fetching sites:', error);
    }
  };

  const handleOpen = (station = null) => {
    if (station) {
      setIsEdit(true);
      setSelectedStation(station);
      setFormData({
        charger_id: station.charger_id,
        name: station.name,
        site_id: station.site_id || '',
        vendor: station.vendor || '',
        model: station.modelName || '',
        serial_number: station.serial_number || '',
        ocpp_password: '', // Don't show password
        connectors: station.connectors // preserve existing connectors
      });
    } else {
      setIsEdit(false);
      setSelectedStation(null);
      setFormData({
        charger_id: '',
        name: '',
        site_id: '',
        vendor: '',
        model: '',
        serial_number: '',
        ocpp_password: '',
        connectors: [{ type: 'Type2', max_power_kw: 22.0 }]
      });
    }
    setOpen(true);
  };

  const handleClose = () => {
    setOpen(false);
    setViewOpen(false);
  };

  const handleViewOpen = (station) => {
    setSelectedStation(station);
    setViewOpen(true);
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleAddConnector = () => {
    setFormData(prev => ({
      ...prev,
      connectors: [...prev.connectors, { type: 'Type2', max_power_kw: 22.0 }]
    }));
  };

  const handleRemoveConnector = (index) => {
    setFormData(prev => ({
      ...prev,
      connectors: prev.connectors.filter((_, i) => i !== index)
    }));
  };

  const handleConnectorChange = (index, field, value) => {
    const newConnectors = [...formData.connectors];
    newConnectors[index] = { ...newConnectors[index], [field]: value };
    setFormData(prev => ({ ...prev, connectors: newConnectors }));
  };

  const handleSubmit = async () => {
    try {
      if (isEdit) {
        await StationService.updateStation(selectedStation.charger_id, formData);
      } else {
        await StationService.createStation(formData);
      }
      fetchStations();
      handleClose();
    } catch (error) {
      console.error('Error saving station:', error);
      alert(error.response?.data?.message || 'Error saving station');
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this station?')) {
      try {
        await StationService.deleteStation(id);
        fetchStations();
      } catch (error) {
        console.error('Error deleting station:', error);
        alert(error.response?.data?.message || 'Error deleting station');
      }
    }
  };

  const getStatusColor = (status) => {
    switch (status?.toLowerCase()) {
      case 'available': return 'success';
      case 'charging': return 'info';
      case 'offline': return 'default';
      case 'faulted': return 'error';
      default: return 'warning';
    }
  };

  const getSiteName = (siteId) => {
    const site = sites.find(s => s._id === siteId);
    return site ? site.name : siteId;
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <MainCard title="Charging Stations" secondary={
      <Button variant="contained" startIcon={<Add />} onClick={() => handleOpen()}>
        Add Station
      </Button>
    }>
      <TableContainer component={Paper} sx={{ boxShadow: 'none', border: '1px solid', borderColor: 'divider' }}>
        <Table sx={{ minWidth: 650 }} aria-label="stations table">
          <TableHead>
            <TableRow>
              <TableCell>Charger ID</TableCell>
              <TableCell>Name</TableCell>
              <TableCell>Site</TableCell>
              <TableCell>Vendor/Model</TableCell>
              <TableCell>Status</TableCell>
              <TableCell align="right">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {stations.map((station, index) => (
              <TableRow key={station.charger_id} sx={{ backgroundColor: index % 2 !== 0 ? theme.palette.secondary.lighter : 'inherit' }}>
                <TableCell>
                  <Stack direction="row" spacing={1.5} alignItems="center">
                    <Convert3DCube size={18} variant="Bold" />
                    <Typography variant="subtitle1">{station.charger_id}</Typography>
                  </Stack>
                </TableCell>
                <TableCell>{station.name}</TableCell>
                <TableCell>{getSiteName(station.site_id)}</TableCell>
                <TableCell>
                  <Typography variant="body2">{station.vendor}</Typography>
                  <Typography variant="caption" color="textSecondary">{station.modelName}</Typography>
                </TableCell>
                <TableCell>
                  <Chip 
                    label={station.status} 
                    color={getStatusColor(station.status)} 
                    size="small" 
                    variant="outlined"
                  />
                </TableCell>
                <TableCell align="right">
                  <Tooltip title="View Details">
                    <IconButton color="secondary" onClick={() => handleViewOpen(station)}>
                      <Eye variant="Bold" size={20}/>
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Edit">
                    <IconButton color="primary" onClick={() => handleOpen(station)}>
                      <Edit variant="Bold" size={20}/>
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Delete">
                    <IconButton color="error" onClick={() => handleDelete(station.charger_id)}>
                      <Trash variant="Bold" size={20}/>
                    </IconButton>
                  </Tooltip>
                </TableCell>
              </TableRow>
            ))}
            {stations.length === 0 && (
              <TableRow>
                <TableCell colSpan={6} align="center">
                  No charging stations found
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Create/Edit Dialog */}
      <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
        <DialogTitle>{isEdit ? 'Edit Station' : 'Create Station'}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField
              name="charger_id"
              label="Charger ID (OCPP Identity)"
              fullWidth
              value={formData.charger_id}
              onChange={handleInputChange}
              disabled={isEdit}
              required
            />
            <TextField
              name="name"
              label="Station Name"
              fullWidth
              value={formData.name}
              onChange={handleInputChange}
            />
             <FormControl fullWidth>
              <InputLabel>Site</InputLabel>
              <Select
                name="site_id"
                value={formData.site_id}
                label="Site"
                onChange={handleInputChange}
              >
                {sites.map((site) => (
                  <MenuItem key={site._id} value={site._id}>
                    {site.name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            <Stack direction="row" spacing={2}>
              <TextField
                name="vendor"
                label="Vendor"
                fullWidth
                value={formData.vendor}
                onChange={handleInputChange}
              />
              <TextField
                name="model"
                label="Model"
                fullWidth
                value={formData.model}
                onChange={handleInputChange}
              />
            </Stack>
            <TextField
              name="serial_number"
              label="Serial Number"
              fullWidth
              value={formData.serial_number}
              onChange={handleInputChange}
            />
            {!isEdit && (
                <TextField
                name="ocpp_password"
                label="OCPP Password (Optional - auto-generated if blank)"
                fullWidth
                value={formData.ocpp_password}
                onChange={handleInputChange}
                />
            )}
            
            <Typography variant="subtitle1" sx={{ mt: 2 }}>Connectors</Typography>
            {formData.connectors.map((connector, index) => (
                <Stack key={index} direction="row" spacing={2} alignItems="center">
                    <Typography>{index + 1}.</Typography>
                    <FormControl fullWidth size="small">
                        <InputLabel>Type</InputLabel>
                        <Select
                            value={connector.type}
                            label="Type"
                            onChange={(e) => handleConnectorChange(index, 'type', e.target.value)}
                        >
                            <MenuItem value="Type2">Type 2</MenuItem>
                            <MenuItem value="CCS2">CCS 2</MenuItem>
                            <MenuItem value="Chademo">CHAdeMO</MenuItem>
                            <MenuItem value="Type1">Type 1</MenuItem>
                            <MenuItem value="BharatDC001">Bharat DC001</MenuItem>
                            <MenuItem value="BharatAC001">Bharat AC001</MenuItem>
                        </Select>
                    </FormControl>
                    <TextField
                        label="Max Power (kW)"
                        type="number"
                        size="small"
                        value={connector.max_power_kw}
                        onChange={(e) => handleConnectorChange(index, 'max_power_kw', e.target.value)}
                    />
                    <IconButton color="error" onClick={() => handleRemoveConnector(index)} disabled={formData.connectors.length === 1}>
                        <Trash size={18}/>
                    </IconButton>
                </Stack>
            ))}
            <Button startIcon={<Add />} onClick={handleAddConnector} variant="outlined" size="small">
                Add Connector
            </Button>
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
            <Convert3DCube size={24} variant="Bold" />
            Station Details
        </DialogTitle>
        <DialogContent dividers>
            {selectedStation && (
              <Grid container spacing={2}>
                 <Grid size={{ xs: 12 }}>
                    <MainCard content={false} sx={{ p: 2 }}>
                         <Stack direction="row" spacing={2} alignItems="center">
                            <Box sx={{ width: 48, height: 48, borderRadius: '12px', bgcolor: 'primary.lighter', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <Box1 size={24} color="#333" variant="Bold" />
                            </Box>
                            <Stack>
                                <Typography variant="h5">{selectedStation.name}</Typography>
                                <Typography variant="caption" color="textSecondary">Charger ID: {selectedStation.charger_id}</Typography>
                            </Stack>
                             <Box sx={{ flexGrow: 1 }} />
                             <Chip 
                                label={selectedStation.status} 
                                color={getStatusColor(selectedStation.status)} 
                                size="small" 
                                variant="combined"
                            />
                        </Stack>
                    </MainCard>
                </Grid>

                 <Grid size={{ xs: 12 }}>
                    <Typography variant="h6" sx={{ mb: 2 }}>Technical Specifications</Typography>
                    <Grid container spacing={2}>
                        <Grid size={{ xs: 6 }}>
                             <MainCard content={false} sx={{ p: 2 }}>
                                <Stack spacing={1}>
                                    <Stack direction="row" spacing={1} alignItems="center">
                                        <Cpu size={18} color="#666" />
                                        <Typography variant="caption" color="textSecondary">Model</Typography>
                                    </Stack>
                                    <Typography variant="body1">{selectedStation.vendor}</Typography>
                                    <Typography variant="caption">{selectedStation.modelName || 'N/A'}</Typography>
                                </Stack>
                            </MainCard>
                        </Grid>
                         <Grid size={{ xs: 6 }}>
                             <MainCard content={false} sx={{ p: 2 }}>
                                <Stack spacing={1}>
                                    <Stack direction="row" spacing={1} alignItems="center">
                                        <Barcode size={18} color="#666" />
                                        <Typography variant="caption" color="textSecondary">Serial Number</Typography>
                                    </Stack>
                                    <Typography variant="body1">{selectedStation.serial_number || 'N/A'}</Typography>
                                </Stack>
                            </MainCard>
                        </Grid>
                    </Grid>
                 </Grid>

                 <Grid size={{ xs: 12 }}>
                     <Typography variant="h6" sx={{ mb: 2 }}>Site Information</Typography>
                     <MainCard content={false} sx={{ p: 2 }}>
                         <Stack direction="row" spacing={1} alignItems="center">
                            <Location size={20} color="#666" />
                            <Typography variant="body1">{getSiteName(selectedStation.site_id)}</Typography>
                        </Stack>
                     </MainCard>
                 </Grid>

                  <Grid size={{ xs: 12 }}>
                     <Typography variant="h6" sx={{ mb: 2 }}>Connectors</Typography>
                     <MainCard content={false}>
                        <Stack divider={<Divider />}>
                             {selectedStation.connectors && selectedStation.connectors.map((conn, idx) => (
                                 <Stack key={idx} direction="row" alignItems="center" justifyContent="space-between" sx={{ p: 2 }}>
                                     <Stack direction="row" spacing={2} alignItems="center">
                                         <Box sx={{ width: 32, height: 32, borderRadius: '50%', bgcolor: 'secondary.lighter', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                             <Typography variant="subtitle2">{idx+1}</Typography>
                                         </Box>
                                         <Box>
                                             <Typography variant="subtitle1">{conn.type}</Typography>
                                             <Typography variant="caption" color="textSecondary">Max Power: {conn.max_power_kw} kW</Typography>
                                         </Box>
                                     </Stack>
                                     <Chip label={conn.status} size="small" color={conn.status === 'Available' ? 'success' : 'default'} variant="light" />
                                 </Stack>
                             ))}
                        </Stack>
                     </MainCard>
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
