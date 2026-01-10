import { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
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
import { Edit, Trash, Add, Convert3DCube, Eye, Box1, Cpu, Electricity, Barcode, Wifi, Location, Activity } from 'iconsax-reactjs';

// project-imports
import MainCard from 'components/MainCard';
import ChargerService from 'api/charger';
import SiteService from 'api/site';
import TariffService from 'api/tariff';

export default function ChargersList() {
  const theme = useTheme();
  const location = useLocation();
  const navigate = useNavigate();
  const [chargers, setChargers] = useState([]);
  const [sites, setSites] = useState([]);
  const [tariffs, setTariffs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [open, setOpen] = useState(false);
  const [viewOpen, setViewOpen] = useState(false);
  const [isEdit, setIsEdit] = useState(false);
  const [selectedCharger, setSelectedCharger] = useState(null);

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
    connectors: [{ type: 'Type2', max_power_kw: 22.0 }], // Simple default for now
    tariff_id: ''
  });

  useEffect(() => {
    Promise.all([
      fetchChargers(),
      fetchSites(),
      fetchTariffs()
    ]).finally(() => setLoading(false));
  }, []);

  const fetchChargers = async () => {
    try {
      const response = await ChargerService.getAllChargers();
      if (!response.data.error) {
        setChargers(response.data.data);
      }
    } catch (error) {
      console.error('Error fetching chargers:', error);
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

  const fetchTariffs = async () => {
    try {
      const response = await TariffService.getAllTariffs();
      if (!response.data.error) {
        setTariffs(response.data.data);
      }
    } catch (error) {
      console.error('Error fetching tariffs:', error);
    }
  };

  const handleOpen = (charger = null) => {
    if (charger) {
      setIsEdit(true);
      setSelectedCharger(charger);
      setFormData({
        charger_id: charger.charger_id,
        name: charger.name,
        site_id: charger.site_id || '',
        vendor: charger.vendor || '',
        model: charger.modelName || '',
        serial_number: charger.serial_number || '',
        ocpp_password: '', // Don't show password
        connectors: charger.connectors, // preserve existing connectors
        tariff_id: charger.tariff_id || ''
      });
    } else {
      setIsEdit(false);
      setSelectedCharger(null);
      setFormData({
        charger_id: '',
        name: '',
        site_id: '',
        vendor: '',
        model: '',
        serial_number: '',
        ocpp_password: '',
        connectors: [{ type: 'Type2', max_power_kw: 22.0 }],
        tariff_id: ''
      });
    }
    setOpen(true);
  };

  const handleClose = () => {
    setOpen(false);
    setViewOpen(false);
  };

  const handleViewOpen = (charger) => {
    setSelectedCharger(charger);
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
        await ChargerService.updateCharger(selectedCharger.charger_id, formData);
      } else {
        await ChargerService.createCharger(formData);
      }
      fetchChargers();
      handleClose();
    } catch (error) {
      console.error('Error saving charger:', error);
      alert(error.response?.data?.message || 'Error saving charger');
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this charger?')) {
      try {
        await ChargerService.deleteCharger(id);
        fetchChargers();
      } catch (error) {
        console.error('Error deleting charger:', error);
        alert(error.response?.data?.message || 'Error deleting charger');
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
    <MainCard title="Chargers" secondary={
      <Button variant="contained" startIcon={<Add />} onClick={() => handleOpen()}>
        Add Charger
      </Button>
    }>
      <TableContainer component={Paper} sx={{ boxShadow: 'none', border: '1px solid', borderColor: 'divider' }}>
        <Table sx={{ minWidth: 650 }} aria-label="chargers table">
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
            {chargers.map((charger, index) => (
              <TableRow key={charger.charger_id} sx={{ backgroundColor: index % 2 !== 0 ? theme.palette.secondary.lighter : 'inherit' }}>
                <TableCell>
                  <Stack direction="row" spacing={1.5} alignItems="center">
                    <Convert3DCube size={18} variant="Bold" />
                    <Typography variant="subtitle1">{charger.charger_id}</Typography>
                  </Stack>
                </TableCell>
                <TableCell>{charger.name}</TableCell>
                <TableCell>{getSiteName(charger.site_id)}</TableCell>
                <TableCell>
                  <Typography variant="body2">{charger.vendor}</Typography>
                  <Typography variant="caption" color="textSecondary">{charger.modelName}</Typography>
                </TableCell>
                <TableCell>
                  <Chip 
                    label={charger.status} 
                    color={getStatusColor(charger.status)} 
                    size="small" 
                    variant="outlined"
                  />
                </TableCell>
                <TableCell align="right">
                  <Tooltip title="View Sessions">
                    <IconButton color="info" onClick={() => navigate(`/chargers/sessions?charger_id=${charger.charger_id}`)}>
                      <Activity variant="Bold" size={20}/>
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="View Details">
                    <IconButton color="secondary" onClick={() => handleViewOpen(charger)}>
                      <Eye variant="Bold" size={20}/>
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Edit">
                    <IconButton color="primary" onClick={() => handleOpen(charger)}>
                      <Edit variant="Bold" size={20}/>
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Delete">
                    <IconButton color="error" onClick={() => handleDelete(charger.charger_id)}>
                      <Trash variant="Bold" size={20}/>
                    </IconButton>
                  </Tooltip>
                </TableCell>
              </TableRow>
            ))}
            {chargers.length === 0 && (
              <TableRow>
                <TableCell colSpan={6} align="center">
                  No chargers found
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Create/Edit Dialog */}
      <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
        <DialogTitle>{isEdit ? 'Edit Charger' : 'Create Charger'}</DialogTitle>
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
              label="Charger Name"
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

            <FormControl fullWidth>
              <InputLabel id="st-tariff-select-label">Override Tariff (Optional)</InputLabel>
              <Select
                labelId="st-tariff-select-label"
                name="tariff_id"
                value={formData.tariff_id}
                label="Override Tariff (Optional)"
                onChange={handleInputChange}
              >
                 <MenuItem value="">
                   <em>Use Site Default</em>
                 </MenuItem>
                {tariffs.map((tariff) => (
                  <MenuItem key={tariff._id} value={tariff._id}>
                    {tariff.name} ({tariff.currency} {tariff.price_per_kwh}/kWh)
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
    </MainCard>
  );
}
