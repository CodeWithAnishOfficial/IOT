import { useState, useEffect } from 'react';
import { useTheme } from '@mui/material/styles';

// material-ui
import {
  Grid,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Box,
  Button,
  IconButton,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Stack,
  Alert,
  Typography,
  Chip,
  Divider
} from '@mui/material';

// assets
import { Add, Edit, Trash, AddCircle, MinusCirlce, Eye, Money, Timer, Status, Receipt1 } from 'iconsax-reactjs';

// project-imports
import MainCard from 'components/MainCard';
import TariffService from 'api/tariff';

export default function TariffsList() {
  const theme = useTheme();
  const [tariffs, setTariffs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [open, setOpen] = useState(false);
  const [viewOpen, setViewOpen] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [selectedId, setSelectedId] = useState(null);
  const [selectedTariff, setSelectedTariff] = useState(null);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  const initialFormState = {
    name: '',
    type: 'FLAT',
    currency: 'INR',
    price_per_kwh: '',
    idle_fee_per_min: 0,
    peak_multiplier: 1.0,
    peak_hours: []
  };

  const [formData, setFormData] = useState(initialFormState);

  useEffect(() => {
    fetchTariffs();
  }, []);

  const fetchTariffs = async () => {
    try {
      const response = await TariffService.getAllTariffs();
      if (!response.data.error) {
        setTariffs(response.data.data);
      }
    } catch (error) {
      console.error('Error fetching tariffs:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleOpen = () => {
    setEditMode(false);
    setFormData(initialFormState);
    setOpen(true);
    setError(null);
  };

  const handleEdit = (tariff) => {
    setEditMode(true);
    setSelectedId(tariff._id);
    setFormData({
      name: tariff.name,
      type: tariff.type,
      currency: tariff.currency,
      price_per_kwh: tariff.price_per_kwh,
      idle_fee_per_min: tariff.idle_fee_per_min || 0,
      peak_multiplier: tariff.peak_multiplier || 1.0,
      peak_hours: tariff.peak_hours || []
    });
    setOpen(true);
    setError(null);
  };

  const handleClose = () => {
    setOpen(false);
    setViewOpen(false);
    setError(null);
  };

  const handleViewOpen = (tariff) => {
    setSelectedTariff(tariff);
    setViewOpen(true);
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value
    }));
  };

  const handleAddPeakHour = () => {
    setFormData((prev) => ({
      ...prev,
      peak_hours: [...prev.peak_hours, { start_time: '18:00', end_time: '21:00' }]
    }));
  };

  const handleRemovePeakHour = (index) => {
    const updatedPeakHours = formData.peak_hours.filter((_, i) => i !== index);
    setFormData((prev) => ({
      ...prev,
      peak_hours: updatedPeakHours
    }));
  };

  const handlePeakHourChange = (index, field, value) => {
    const updatedPeakHours = [...formData.peak_hours];
    updatedPeakHours[index][field] = value;
    setFormData((prev) => ({
      ...prev,
      peak_hours: updatedPeakHours
    }));
  };

  const handleSubmit = async () => {
    setError(null);
    try {
      if (editMode) {
        await TariffService.updateTariff(selectedId, formData);
        setSuccess('Tariff updated successfully');
      } else {
        await TariffService.createTariff(formData);
        setSuccess('Tariff created successfully');
      }
      handleClose();
      fetchTariffs();
      setTimeout(() => setSuccess(null), 3000);
    } catch (error) {
      setError(error.response?.data?.message || 'Error saving tariff');
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this tariff?')) {
      try {
        await TariffService.deleteTariff(id);
        setSuccess('Tariff deleted successfully');
        fetchTariffs();
        setTimeout(() => setSuccess(null), 3000);
      } catch (error) {
        alert(error.response?.data?.message || 'Error deleting tariff');
      }
    }
  };

  return (
    <MainCard title="Tariffs" secondary={
      <Button variant="contained" startIcon={<Add />} onClick={handleOpen}>
        Add Tariff
      </Button>
    }>
      {success && (
        <Alert severity="success" sx={{ mb: 2 }}>
          {success}
        </Alert>
      )}

      <TableContainer component={Paper} sx={{ boxShadow: 'none', border: '1px solid', borderColor: 'divider' }}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Name</TableCell>
              <TableCell>Type</TableCell>
              <TableCell>Price (per kWh)</TableCell>
              <TableCell>Currency</TableCell>
              <TableCell>Idle Fee (per min)</TableCell>
              <TableCell>Peak Multiplier</TableCell>
              <TableCell align="right">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {tariffs.map((tariff, index) => (
              <TableRow key={tariff._id} sx={{ backgroundColor: index % 2 !== 0 ? theme.palette.secondary.lighter : 'inherit' }}>
                <TableCell>{tariff.name}</TableCell>
                <TableCell>
                  <Chip 
                    label={tariff.type} 
                    color={tariff.type === 'FLAT' ? 'primary' : 'secondary'} 
                    size="small" 
                  />
                </TableCell>
                <TableCell>{tariff.price_per_kwh}</TableCell>
                <TableCell>{tariff.currency}</TableCell>
                <TableCell>{tariff.idle_fee_per_min}</TableCell>
                <TableCell>{tariff.type === 'TOU' ? tariff.peak_multiplier : '-'}</TableCell>
                <TableCell align="right">
                  <Stack direction="row" spacing={1} justifyContent="flex-end">
                    <Tooltip title="View Details">
                      <IconButton color="secondary" onClick={() => handleViewOpen(tariff)}>
                        <Eye size="18" variant="Bold" />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Edit">
                      <IconButton color="primary" onClick={() => handleEdit(tariff)}>
                        <Edit size="18" />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Delete">
                      <IconButton color="error" onClick={() => handleDelete(tariff._id)}>
                        <Trash size="18" />
                      </IconButton>
                    </Tooltip>
                  </Stack>
                </TableCell>
              </TableRow>
            ))}
            {tariffs.length === 0 && !loading && (
              <TableRow>
                <TableCell colSpan={7} align="center">
                  No tariffs found
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Add/Edit Dialog */}
      <Dialog open={open} onClose={handleClose} maxWidth="md" fullWidth>
        <DialogTitle>{editMode ? 'Edit Tariff' : 'Add New Tariff'}</DialogTitle>
        <DialogContent>
          <Stack spacing={3} sx={{ mt: 1 }}>
            {error && <Alert severity="error">{error}</Alert>}
            
            <TextField
              name="name"
              label="Tariff Name"
              fullWidth
              value={formData.name}
              onChange={handleInputChange}
            />

            <Grid container spacing={2}>
              <Grid size={{ xs: 12, md: 6 }}>
                 <FormControl fullWidth>
                  <InputLabel>Type</InputLabel>
                  <Select
                    name="type"
                    value={formData.type}
                    label="Type"
                    onChange={handleInputChange}
                  >
                    <MenuItem value="FLAT">Flat Rate</MenuItem>
                    <MenuItem value="TOU">Time of Use (TOU)</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              <Grid size={{ xs: 12, md: 6 }}>
                <TextField
                  name="currency"
                  label="Currency"
                  fullWidth
                  value={formData.currency}
                  onChange={handleInputChange}
                />
              </Grid>
            </Grid>

            <Grid container spacing={2}>
              <Grid size={{ xs: 12, md: 6 }}>
                <TextField
                  name="price_per_kwh"
                  label="Price per kWh"
                  type="number"
                  fullWidth
                  value={formData.price_per_kwh}
                  onChange={handleInputChange}
                />
              </Grid>
              <Grid size={{ xs: 12, md: 6 }}>
                <TextField
                  name="idle_fee_per_min"
                  label="Idle Fee per Minute"
                  type="number"
                  fullWidth
                  value={formData.idle_fee_per_min}
                  onChange={handleInputChange}
                />
              </Grid>
            </Grid>

            {formData.type === 'TOU' && (
              <>
                <Typography variant="h6">Time of Use Settings</Typography>
                
                <TextField
                  name="peak_multiplier"
                  label="Peak Multiplier (e.g., 1.5 for 50% extra)"
                  type="number"
                  fullWidth
                  value={formData.peak_multiplier}
                  onChange={handleInputChange}
                  helperText="Price during peak hours = Base Price * Multiplier"
                />

                <Typography variant="subtitle1">Peak Hours</Typography>
                {formData.peak_hours.map((hour, index) => (
                  <Grid container spacing={2} key={index} alignItems="center">
                    <Grid size={{ xs: 5 }}>
                      <TextField
                        label="Start Time"
                        type="time"
                        fullWidth
                        value={hour.start_time}
                        onChange={(e) => handlePeakHourChange(index, 'start_time', e.target.value)}
                        InputLabelProps={{ shrink: true }}
                      />
                    </Grid>
                    <Grid size={{ xs: 5 }}>
                      <TextField
                        label="End Time"
                        type="time"
                        fullWidth
                        value={hour.end_time}
                        onChange={(e) => handlePeakHourChange(index, 'end_time', e.target.value)}
                        InputLabelProps={{ shrink: true }}
                      />
                    </Grid>
                    <Grid size={{ xs: 2 }}>
                      <IconButton color="error" onClick={() => handleRemovePeakHour(index)}>
                        <MinusCirlce />
                      </IconButton>
                    </Grid>
                  </Grid>
                ))}
                
                <Button 
                  startIcon={<AddCircle />} 
                  onClick={handleAddPeakHour} 
                  variant="outlined" 
                  size="small"
                  sx={{ width: 'fit-content' }}
                >
                  Add Peak Hours
                </Button>
              </>
            )}

          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose} color="secondary">
            Cancel
          </Button>
          <Button onClick={handleSubmit} variant="contained">
            {editMode ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* View Details Dialog */}
      <Dialog open={viewOpen} onClose={handleClose} maxWidth="sm" fullWidth>
        <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Receipt1 size={24} variant="Bold" />
            Tariff Details
        </DialogTitle>
        <DialogContent dividers>
            {selectedTariff && (
              <Grid container spacing={2}>
                 <Grid size={{ xs: 12 }}>
                    <MainCard content={false} sx={{ p: 2 }}>
                        <Stack direction="row" spacing={2} alignItems="center">
                            <Box sx={{ width: 48, height: 48, borderRadius: '12px', bgcolor: 'primary.lighter', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <Money size={24} color="#333" variant="Bold" />
                            </Box>
                            <Stack>
                                <Typography variant="h5">{selectedTariff.name}</Typography>
                                <Typography variant="caption" color="textSecondary">ID: {selectedTariff._id}</Typography>
                            </Stack>
                            <Box sx={{ flexGrow: 1 }} />
                             <Chip 
                                label={selectedTariff.type} 
                                color={selectedTariff.type === 'FLAT' ? 'primary' : 'secondary'} 
                                size="small" 
                                variant="combined"
                            />
                        </Stack>
                    </MainCard>
                </Grid>

                 <Grid size={{ xs: 12 }}>
                    <Typography variant="h6" sx={{ mb: 2 }}>Pricing</Typography>
                     <Grid container spacing={2}>
                        <Grid size={{ xs: 6 }}>
                            <MainCard content={false} sx={{ p: 2 }}>
                                <Stack spacing={1}>
                                    <Stack direction="row" spacing={1} alignItems="center">
                                        <Money size={18} color="#666" />
                                        <Typography variant="caption" color="textSecondary">Base Price</Typography>
                                    </Stack>
                                    <Typography variant="h6">{selectedTariff.price_per_kwh} {selectedTariff.currency} / kWh</Typography>
                                </Stack>
                            </MainCard>
                        </Grid>
                        <Grid size={{ xs: 6 }}>
                            <MainCard content={false} sx={{ p: 2 }}>
                                <Stack spacing={1}>
                                    <Stack direction="row" spacing={1} alignItems="center">
                                        <Timer size={18} color="#666" />
                                        <Typography variant="caption" color="textSecondary">Idle Fee</Typography>
                                    </Stack>
                                    <Typography variant="h6">{selectedTariff.idle_fee_per_min || 0} {selectedTariff.currency} / min</Typography>
                                </Stack>
                            </MainCard>
                        </Grid>
                     </Grid>
                 </Grid>

                {selectedTariff.type === 'TOU' && (
                     <Grid size={{ xs: 12 }}>
                        <Typography variant="h6" sx={{ mb: 2 }}>Time of Use (TOU)</Typography>
                        <MainCard content={false}>
                            <Stack divider={<Divider />}>
                                 <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ p: 2 }}>
                                     <Stack direction="row" spacing={1} alignItems="center">
                                        <Status size={20} color="#666" />
                                        <Typography variant="subtitle1">Peak Multiplier</Typography>
                                     </Stack>
                                     <Chip label={`x${selectedTariff.peak_multiplier}`} color="warning" size="small" variant="light" />
                                 </Stack>
                                 <Box sx={{ p: 2 }}>
                                    <Typography variant="subtitle2" sx={{ mb: 1 }}>Peak Hours Schedule</Typography>
                                    {selectedTariff.peak_hours && selectedTariff.peak_hours.length > 0 ? (
                                        <Grid container spacing={1}>
                                            {selectedTariff.peak_hours.map((ph, idx) => (
                                                <Grid size={{ xs: 6 }} key={idx}>
                                                    <Box sx={{ p: 1, bgcolor: 'secondary.lighter', borderRadius: 1, textAlign: 'center' }}>
                                                        <Typography variant="body2" fontWeight="500">{ph.start_time} - {ph.end_time}</Typography>
                                                    </Box>
                                                </Grid>
                                            ))}
                                        </Grid>
                                    ) : (
                                        <Typography variant="body2" color="textSecondary">No peak hours defined.</Typography>
                                    )}
                                 </Box>
                            </Stack>
                        </MainCard>
                     </Grid>
                )}
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
