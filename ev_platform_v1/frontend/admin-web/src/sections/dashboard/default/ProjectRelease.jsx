import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

// material-ui
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import Grid from '@mui/material/Grid';
import LinearProgress from '@mui/material/LinearProgress';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';

// project-imports
import MainCard from 'components/MainCard';
import Dot from 'components/@extended/Dot';
import DashboardService from 'api/dashboard';

// assets
import { Add, Link1, Flash } from 'iconsax-reactjs';

// =========================|| DATA WIDGET - NETWORK HEALTH ||========================= //

export default function ProjectRelease() {
  const navigate = useNavigate();
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  // Default data provided by user
  const stationData = {
    _id: "694e3152f59bbdf0fd4b84a5",
    charger_id: "CH001",
    name: "AnishKumar station 1",
    status: "offline",
    max_power_kw: 22,
    connectors: [
      {
        connector_id: 1,
        status: "Available",
        type: "Type2",
        max_power_kw: 22
      }
    ]
  };

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      const response = await DashboardService.getStats();
      if (!response.data.error) {
        setStats(response.data.data);
      }
    } catch (error) {
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const onlinePercentage = stats ? Math.round((stats.stations.online / stats.stations.total) * 100) : 0;

  return (
    <MainCard title="Quantum Network Health">
      <Grid container spacing={1.5}>
        <Grid size={12}>
          <Stack sx={{ gap: 1 }}>
            <Stack direction="row" sx={{ alignItems: 'center', justifyContent: 'space-between' }}>
              <Typography>System Uptime</Typography>
              <Typography>{onlinePercentage}%</Typography>
            </Stack>
            <LinearProgress variant="determinate" value={onlinePercentage} color={onlinePercentage > 90 ? "success" : "warning"} />
          </Stack>
        </Grid>
        <Grid size={12}>
          <List>
            <ListItemButton sx={{ flexWrap: 'wrap', rowGap: 1 }}>
              <ListItemIcon>
                <Dot color={stationData.status === 'online' ? 'success' : 'error'} />
              </ListItemIcon>
              <ListItemText 
                primary={stationData.name} 
                secondary={`ID: ${stationData.charger_id}`}
              />
              <Chip
                label={stationData.status}
                size="small"
                color={stationData.status === 'online' ? 'success' : 'error'}
                sx={{ borderRadius: 1, textTransform: 'capitalize' }}
              />
            </ListItemButton>
            
            {stationData.connectors.map((connector) => (
               <ListItemButton key={connector.connector_id}>
                <ListItemIcon>
                  <Dot color={connector.status === 'Available' ? 'success' : 'warning'} />
                </ListItemIcon>
                <ListItemText primary={`${connector.type} Connector`} />
                <Chip
                    label={connector.status}
                    size="small"
                    variant="outlined"
                    color={connector.status === 'Available' ? 'success' : 'warning'}
                    sx={{ borderRadius: 1 }}
                />
              </ListItemButton>
            ))}
          </List>
        </Grid>
        <Grid size={12}>
          <Button fullWidth variant="contained" startIcon={<Add />} onClick={() => navigate('/charging-stations', { state: { openAdd: true } })}>
            Add Station
          </Button>
        </Grid>
      </Grid>
    </MainCard>
  );
}
