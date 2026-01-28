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
  Tooltip,
  IconButton
} from '@mui/material';

// icons
import { Convert3DCube, Eye, User, Money } from 'iconsax-reactjs';

// project-imports
import MainCard from 'components/MainCard';
import ChargerService from 'api/charger';

export default function CommercialChargers() {
  const theme = useTheme();
  const [chargers, setChargers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchChargers();
  }, []);

  const fetchChargers = async () => {
    try {
      const response = await ChargerService.getAllChargers({ type: 'commercial' });
      if (!response.data.error) {
        setChargers(response.data.data);
      }
    } catch (error) {
      console.error('Error fetching commercial chargers:', error);
    } finally {
      setLoading(false);
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

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <MainCard title="Commercial Chargers">
      <TableContainer component={Paper} sx={{ boxShadow: 'none', border: '1px solid', borderColor: 'divider' }}>
        <Table sx={{ minWidth: 650 }} aria-label="commercial chargers table">
          <TableHead>
            <TableRow>
              <TableCell>Charger ID</TableCell>
              <TableCell>Location / Site</TableCell>
              <TableCell>Owner ID</TableCell>
              <TableCell>Price/kWh</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Public</TableCell>
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
                <TableCell>
                    <Stack spacing={0.5}>
                        <Typography variant="subtitle2">{charger.site_id?.name || charger.name || 'Unknown Site'}</Typography>
                        <Typography variant="caption" color="textSecondary">{charger.site_id?.address || 'No Address'}</Typography>
                    </Stack>
                </TableCell>
                <TableCell>
                  <Stack direction="row" spacing={1} alignItems="center">
                    <User size={16} />
                    <Typography variant="body2">{charger.owner_id}</Typography>
                  </Stack>
                </TableCell>
                <TableCell>
                   <Stack direction="row" spacing={1} alignItems="center">
                    <Money size={16} />
                    <Typography variant="body2">₹{charger.price_per_kwh}</Typography>
                   </Stack>
                </TableCell>
                <TableCell>
                  <Chip 
                    label={charger.status} 
                    color={getStatusColor(charger.status)} 
                    size="small" 
                    variant="outlined"
                  />
                </TableCell>
                <TableCell>
                    <Chip 
                        label={charger.is_public ? "Public" : "Private"}
                        color={charger.is_public ? "success" : "default"}
                        size="small"
                    />
                </TableCell>
              </TableRow>
            ))}
            {chargers.length === 0 && (
              <TableRow>
                <TableCell colSpan={6} align="center">
                  No commercial chargers found
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>
    </MainCard>
  );
}
