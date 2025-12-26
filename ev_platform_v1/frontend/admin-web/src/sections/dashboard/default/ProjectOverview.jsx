import PropTypes from 'prop-types';
import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';

// material-ui
import { useTheme } from '@mui/material/styles';
import Button from '@mui/material/Button';
import Grid from '@mui/material/Grid';
import ListItemButton from '@mui/material/ListItemButton';
import Menu from '@mui/material/Menu';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';

// third-party
import ReactApexChart from 'react-apexcharts';

// project-imports
import IconButton from 'components/@extended/IconButton';
import MoreIcon from 'components/@extended/MoreIcon';
import MainCard from 'components/MainCard';
import DashboardService from 'api/dashboard';

// assets
import { Add } from 'iconsax-reactjs';

// ==============================|| CHART ||============================== //

function OverviewChart({ color, data }) {
  const theme = useTheme();
  const mode = theme.palette.mode;

  // chart options
  const areaChartOptions = {
    chart: {
      id: 'new-stack-chart',
      type: 'area',
      stacked: true,
      sparkline: {
        enabled: true
      }
    },
    dataLabels: {
      enabled: false
    },
    stroke: { curve: 'smooth', width: 2 },
    fill: {
      type: 'gradient',
      gradient: {
        shadeIntensity: 1,
        type: 'vertical',
        inverseColors: false,
        opacityFrom: 0.5,
        opacityTo: 0
      }
    },
    grid: {
      show: false
    }
  };
  
  const [options, setOptions] = useState(areaChartOptions);

  useEffect(() => {
    setOptions((prevState) => ({
      ...prevState,
      colors: [color],
      theme: {
        mode: 'light'
      }
    }));
  }, [color, mode, theme]);

  const [series, setSeries] = useState([{ name: 'Trend', data: data || [] }]);
  
  useEffect(() => {
      if(data) setSeries([{ name: 'Trend', data }]);
  }, [data]);

  return <ReactApexChart options={options} series={series} type="area" height={60} />;
}

// ==============================|| CHART - INFRASTRUCTURE OVERVIEW ||============================== //

export default function ProjectOverview() {
  const navigate = useNavigate();
  const theme = useTheme();
  const [anchorEl, setAnchorEl] = useState(null);
  
  const [totalStations, setTotalStations] = useState(0);
  const [faultedStations, setFaultedStations] = useState(0);
  const [energyTrend, setEnergyTrend] = useState([0,0,0,0,0,0,0]);
  const [revenueTrend, setRevenueTrend] = useState([0,0,0,0,0,0,0]);

  const open = Boolean(anchorEl);

  const handleClick = (event) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };
  
  useEffect(() => {
      fetchAnalytics();
  }, []);

  const fetchAnalytics = async () => {
    try {
        const response = await DashboardService.getAnalytics();
        if (!response.data.error) {
            const { station_distribution, energy_chart, revenue_chart } = response.data.data;
            
            // Calculate totals
            const total = station_distribution.reduce((sum, item) => sum + item.count, 0);
            const faulted = station_distribution.find(d => d._id === 'faulted')?.count || 0;
            
            setTotalStations(total);
            setFaultedStations(faulted);
            
            // Trends
            if (energy_chart && energy_chart.length > 0) {
                setEnergyTrend(energy_chart.map(e => e.energy / 1000));
            }
            if (revenue_chart && revenue_chart.length > 0) {
                setRevenueTrend(revenue_chart.map(r => r.revenue));
            }
        }
    } catch (error) {
        console.error(error);
    }
  };

  return (
    <MainCard>
      <Stack direction="row" sx={{ gap: 1, alignItems: 'center', justifyContent: 'space-between' }}>
        <Typography variant="h5">Infrastructure Overview</Typography>
        <IconButton
          color="secondary"
          id="wallet-button"
          aria-controls={open ? 'wallet-menu' : undefined}
          aria-haspopup="true"
          aria-expanded={open ? 'true' : undefined}
          onClick={handleClick}
          sx={{ transform: 'rotate(90deg)' }}
        >
          <MoreIcon />
        </IconButton>
        <Menu
          id="wallet-menu"
          anchorEl={anchorEl}
          open={open}
          onClose={handleClose}
          slotProps={{ list: { 'aria-labelledby': 'wallet-button', sx: { p: 1.25, minWidth: 150 } } }}
          anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
          transformOrigin={{ vertical: 'top', horizontal: 'right' }}
        >
          <ListItemButton onClick={handleClose}>Today</ListItemButton>
          <ListItemButton onClick={handleClose}>Weekly</ListItemButton>
          <ListItemButton onClick={handleClose}>Monthly</ListItemButton>
        </Menu>
      </Stack>
      <Grid container spacing={3} sx={{ mt: 1 }}>
        <Grid size={{ xs: 12, sm: 6, md: 4 }}>
          <Grid container spacing={1} sx={{ alignItems: 'flex-end' }}>
            <Grid size={6}>
              <Stack sx={{ gap: 0.25 }}>
                <Typography sx={{ color: 'text.secondary' }}>Total Stations</Typography>
                <Typography variant="h5">{totalStations}</Typography>
              </Stack>
            </Grid>
            <Grid size={6}>
              <OverviewChart color={theme.palette.primary.main} data={energyTrend} />
            </Grid>
          </Grid>
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 4 }}>
          <Grid container spacing={1}>
            <Grid size={6}>
              <Stack sx={{ gap: 0.25 }}>
                <Typography sx={{ color: 'text.secondary' }}>Faulted Stations</Typography>
                <Typography variant="h5">{faultedStations}</Typography>
              </Stack>
            </Grid>
            <Grid size={6}>
              <OverviewChart color={theme.palette.error.main} data={revenueTrend} />
            </Grid>
          </Grid>
        </Grid>
        <Grid size={{ xs: 12, md: 4 }}>
          <Button fullWidth variant="contained" startIcon={<Add />} size="large" onClick={() => navigate('/charging-stations', { state: { openAdd: true } })}>
            Add Station
          </Button>
        </Grid>
      </Grid>
    </MainCard>
  );
}

OverviewChart.propTypes = { color: PropTypes.string, data: PropTypes.array };
