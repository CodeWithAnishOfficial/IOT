import { useState, useEffect } from 'react';
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
  Typography,
  Stack,
  FormControl,
  Select,
  MenuItem,
  InputLabel,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  IconButton,
  Tooltip,
  Grid,
  Divider
} from '@mui/material';

// icons
import { Flash, Clock, Money, Eye, Timer1, Profile, BatteryCharging, Warning2 } from 'iconsax-reactjs';

// project-imports
import MainCard from 'components/MainCard';
import SessionService from 'api/session';

export default function SessionsList() {
  const theme = useTheme();
  const [sessions, setSessions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('');
  const [viewOpen, setViewOpen] = useState(false);
  const [selectedSession, setSelectedSession] = useState(null);

  useEffect(() => {
    fetchSessions();
  }, [statusFilter]);

  const fetchSessions = async () => {
    try {
      setLoading(true);
      const filters = {};
      if (statusFilter && statusFilter !== 'all') {
        filters.status = statusFilter;
      }
      
      const response = await SessionService.getAllSessions(1, 50, filters); // Fetching 50 for now
      if (!response.data.error) {
        setSessions(response.data.data);
      }
    } catch (error) {
      console.error('Error fetching sessions:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleStatusChange = (event) => {
    setStatusFilter(event.target.value);
  };

  const handleViewOpen = (session) => {
    setSelectedSession(session);
    setViewOpen(true);
  };

  const handleClose = () => {
    setViewOpen(false);
  };

  const formatDate = (dateString) => {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleString();
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'active':
        return 'primary';
      case 'completed':
        return 'success';
      case 'error':
        return 'error';
      default:
        return 'default';
    }
  };

  const formatEnergy = (energy) => {
    return `${(energy / 1000).toFixed(2)} kWh`; // Assuming energy is in Wh
  };

  const formatCost = (cost) => {
    return `₹${cost.toFixed(2)}`;
  };

  if (loading && sessions.length === 0) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <MainCard title="Charging Sessions" secondary={
      <FormControl sx={{ minWidth: 120 }} size="small">
        <InputLabel id="status-filter-label">Status</InputLabel>
        <Select
          labelId="status-filter-label"
          id="status-filter"
          value={statusFilter}
          label="Status"
          onChange={handleStatusChange}
        >
          <MenuItem value="all">All</MenuItem>
          <MenuItem value="active">Active</MenuItem>
          <MenuItem value="completed">Completed</MenuItem>
          <MenuItem value="error">Error</MenuItem>
        </Select>
      </FormControl>
    }>
      <TableContainer component={Paper} sx={{ boxShadow: 'none', border: '1px solid', borderColor: 'divider' }}>
        <Table sx={{ minWidth: 650 }} aria-label="sessions table">
          <TableHead>
            <TableRow>
              <TableCell>Session ID</TableCell>
              <TableCell>User / Charger</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Energy</TableCell>
              <TableCell>Cost</TableCell>
              <TableCell>Start Time</TableCell>
              <TableCell>Stop Time</TableCell>
              <TableCell align="right">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {sessions.map((session, index) => (
              <TableRow key={session.session_id} sx={{ backgroundColor: index % 2 !== 0 ? theme.palette.secondary.lighter : 'inherit' }}>
                <TableCell>
                  <Typography variant="subtitle2" sx={{ fontFamily: 'monospace' }}>
                    {session.session_id.substring(0, 8)}...
                  </Typography>
                </TableCell>
                <TableCell>
                  <Typography variant="body2" color="textPrimary">{session.user_id}</Typography>
                  <Typography variant="caption" color="textSecondary">{session.charger_id} (Conn: {session.connector_id})</Typography>
                </TableCell>
                <TableCell>
                  <Chip 
                    label={session.status.toUpperCase()} 
                    color={getStatusColor(session.status)} 
                    size="small" 
                    variant={session.status === 'active' ? 'filled' : 'outlined'}
                  />
                </TableCell>
                <TableCell>
                  <Stack direction="row" spacing={0.5} alignItems="center">
                    <Flash size={16} color="orange"/>
                    <Typography>{formatEnergy(session.total_energy)}</Typography>
                  </Stack>
                </TableCell>
                <TableCell>
                   <Stack direction="row" spacing={0.5} alignItems="center">
                    <Money size={16} color="green"/>
                    <Typography>{formatCost(session.cost)}</Typography>
                  </Stack>
                </TableCell>
                <TableCell>{formatDate(session.start_time)}</TableCell>
                <TableCell>{formatDate(session.stop_time)}</TableCell>
                <TableCell align="right">
                  <Tooltip title="View Details">
                    <IconButton color="secondary" onClick={() => handleViewOpen(session)}>
                      <Eye variant="Bold" size={20}/>
                    </IconButton>
                  </Tooltip>
                </TableCell>
              </TableRow>
            ))}
            {sessions.length === 0 && (
              <TableRow>
                <TableCell colSpan={7} align="center">
                  No sessions found
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* View Details Dialog */}
      <Dialog open={viewOpen} onClose={handleClose} maxWidth="sm" fullWidth>
        <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <BatteryCharging size={24} variant="Bold" />
            Session Details
        </DialogTitle>
        <DialogContent dividers>
            {selectedSession && (
              <Grid container spacing={2}>
                 <Grid size={{ xs: 12 }}>
                    <MainCard content={false} sx={{ p: 2 }}>
                        <Stack direction="row" spacing={2} alignItems="center">
                             <Box sx={{ width: 48, height: 48, borderRadius: '12px', bgcolor: selectedSession.status === 'active' ? 'primary.lighter' : 'secondary.lighter', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <Flash size={24} color={selectedSession.status === 'active' ? '#4680FF' : '#5B6B79'} variant="Bold" />
                            </Box>
                            <Stack>
                                <Typography variant="h5">Session #{selectedSession.session_id.substring(0, 8)}</Typography>
                                <Typography variant="caption" color="textSecondary">Full ID: {selectedSession.session_id}</Typography>
                            </Stack>
                            <Box sx={{ flexGrow: 1 }} />
                             <Chip 
                                label={selectedSession.status.toUpperCase()} 
                                color={getStatusColor(selectedSession.status)} 
                                size="small" 
                                variant={selectedSession.status === 'active' ? 'filled' : 'combined'}
                            />
                        </Stack>
                    </MainCard>
                </Grid>

                <Grid size={{ xs: 12 }}>
                    <Typography variant="h6" sx={{ mb: 2 }}>Overview</Typography>
                    <Grid container spacing={2}>
                         <Grid size={{ xs: 6 }}>
                            <MainCard content={false} sx={{ p: 2 }}>
                                <Stack spacing={1}>
                                    <Stack direction="row" spacing={1} alignItems="center">
                                        <Money size={18} color="#666" />
                                        <Typography variant="caption" color="textSecondary">Total Cost</Typography>
                                    </Stack>
                                    <Typography variant="h6">{formatCost(selectedSession.cost)}</Typography>
                                </Stack>
                            </MainCard>
                         </Grid>
                         <Grid size={{ xs: 6 }}>
                            <MainCard content={false} sx={{ p: 2 }}>
                                <Stack spacing={1}>
                                    <Stack direction="row" spacing={1} alignItems="center">
                                        <Flash size={18} color="#666" />
                                        <Typography variant="caption" color="textSecondary">Energy Consumed</Typography>
                                    </Stack>
                                    <Typography variant="h6">{formatEnergy(selectedSession.total_energy)}</Typography>
                                </Stack>
                            </MainCard>
                         </Grid>
                    </Grid>
                </Grid>

                 <Grid size={{ xs: 12 }}>
                    <Typography variant="h6" sx={{ mb: 2 }}>Participants</Typography>
                    <MainCard content={false}>
                         <Stack divider={<Divider />}>
                             <Stack direction="row" spacing={2} alignItems="center" sx={{ p: 2 }}>
                                <Profile size={20} color="#666" />
                                <Box>
                                    <Typography variant="caption" color="textSecondary">User ID</Typography>
                                    <Typography variant="body1">{selectedSession.user_id}</Typography>
                                </Box>
                            </Stack>
                             <Stack direction="row" spacing={2} alignItems="center" sx={{ p: 2 }}>
                                <BatteryCharging size={20} color="#666" />
                                <Box>
                                    <Typography variant="caption" color="textSecondary">Charger ID</Typography>
                                    <Typography variant="body1">{selectedSession.charger_id}</Typography>
                                    <Typography variant="caption" color="textSecondary">Connector ID: {selectedSession.connector_id}</Typography>
                                </Box>
                            </Stack>
                        </Stack>
                    </MainCard>
                 </Grid>

                 <Grid size={{ xs: 12 }}>
                    <Typography variant="h6" sx={{ mb: 2 }}>Timeline</Typography>
                    <MainCard content={false}>
                        <Stack divider={<Divider />}>
                             <Stack direction="row" spacing={2} alignItems="center" sx={{ p: 2 }}>
                                <Timer1 size={20} color="green" />
                                <Box>
                                    <Typography variant="caption" color="textSecondary">Start Time</Typography>
                                    <Typography variant="body1">{formatDate(selectedSession.start_time)}</Typography>
                                </Box>
                            </Stack>
                             <Stack direction="row" spacing={2} alignItems="center" sx={{ p: 2 }}>
                                <Timer1 size={20} color="red" />
                                <Box>
                                    <Typography variant="caption" color="textSecondary">Stop Time</Typography>
                                    <Typography variant="body1">{formatDate(selectedSession.stop_time)}</Typography>
                                </Box>
                            </Stack>
                        </Stack>
                    </MainCard>
                 </Grid>

                 {selectedSession.error_logs && selectedSession.error_logs.length > 0 && (
                     <Grid size={{ xs: 12 }}>
                        <MainCard content={false} sx={{ p: 2, bgcolor: 'error.lighter', borderColor: 'error.light' }}>
                            <Stack spacing={2}>
                                <Stack direction="row" spacing={1} alignItems="center">
                                    <Warning2 size={20} color="#d32f2f" variant="Bold" />
                                    <Typography variant="subtitle1" color="error.main">Error Logs</Typography>
                                </Stack>
                                <Stack spacing={1}>
                                    {selectedSession.error_logs.map((err, idx) => (
                                         <Typography key={idx} variant="body2" color="error.dark">
                                            • {err.message} <Typography component="span" variant="caption" color="error.main">({formatDate(err.timestamp)})</Typography>
                                         </Typography>
                                    ))}
                                </Stack>
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
