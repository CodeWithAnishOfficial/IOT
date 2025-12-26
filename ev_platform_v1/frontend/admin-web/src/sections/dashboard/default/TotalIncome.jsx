import { useEffect, useState } from 'react';

// material-ui
import { useTheme } from '@mui/material/styles';
import useMediaQuery from '@mui/material/useMediaQuery';
import Grid from '@mui/material/Grid';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';

// third-party
import ReactApexChart from 'react-apexcharts';

// project-imports
import Dot from 'components/@extended/Dot';
import MainCard from 'components/MainCard';
import { GRID_COMMON_SPACING } from 'config';
import DashboardService from 'api/dashboard';

// chart options
const pieChartOptions = {
  chart: {
    type: 'donut',
    height: 320
  },
  labels: ['Online', 'Offline', 'Charging', 'Faulted'],
  legend: {
    show: false
  },
  dataLabels: {
    enabled: false
  }
};

// ==============================|| CHART ||============================== //

function ApexDonutChart({ series }) {
  const theme = useTheme();
  const downSM = useMediaQuery(theme.breakpoints.down('sm'));

  const mode = theme.palette.mode;
  const { primary } = theme.palette.text;
  const line = theme.palette.divider;
  const backColor = theme.palette.background.paper;

  const [options, setOptions] = useState(pieChartOptions);

  useEffect(() => {
    const success = theme.palette.success.main; // Online
    const error = theme.palette.error.main;     // Faulted
    const warning = theme.palette.warning.main; // Offline/Unknown
    const primaryMain = theme.palette.primary.main; // Charging

    setOptions((prevState) => ({
      ...prevState,
      colors: [success, warning, primaryMain, error],
      labels: ['Online', 'Offline', 'Charging', 'Faulted'],
      stroke: {
        colors: [backColor]
      },
      theme: {
        mode: 'light'
      }
    }));
  }, [mode, primary, line, backColor, theme]);

  return (
    <div id="chart">
      <ReactApexChart options={options} series={series} type="donut" height={downSM ? 280 : 320} />
    </div>
  );
}

// ==============================|| CHART WIDGETS - STATION STATUS ||============================== //

export default function StationStatusChart() {
  const [series, setSeries] = useState([0, 0, 0, 0]); // Online, Offline, Charging, Faulted
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchAnalytics();
  }, []);

  const fetchAnalytics = async () => {
    try {
      const response = await DashboardService.getAnalytics();
      if (!response.data.error) {
        const dist = response.data.data.station_distribution;
        // Map backend status to chart series
        const online = dist.find(d => d._id === 'online')?.count || 0;
        const offline = dist.find(d => d._id === 'offline')?.count || 0;
        const charging = dist.find(d => d._id === 'charging')?.count || 0;
        const faulted = dist.find(d => d._id === 'faulted')?.count || 0;
        
        setSeries([online, offline, charging, faulted]);
      }
    } catch (error) {
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <MainCard sx={{ height: '100%' }}>
      <Grid container spacing={GRID_COMMON_SPACING}>
        <Grid size={12}>
          <Typography variant="h5">Station Status</Typography>
        </Grid>
        <Grid size={12} sx={{ '.apexcharts-active': { color: 'common.white' } }}>
          <ApexDonutChart series={series} />
        </Grid>
        {/* Legend */}
        <Grid size={12}>
           <Grid container spacing={2}>
              <Grid item xs={6}>
                 <Stack direction="row" spacing={1} alignItems="center">
                    <Dot color="success" />
                    <Typography>Online ({series[0]})</Typography>
                 </Stack>
              </Grid>
              <Grid item xs={6}>
                 <Stack direction="row" spacing={1} alignItems="center">
                    <Dot color="warning" />
                    <Typography>Offline ({series[1]})</Typography>
                 </Stack>
              </Grid>
              <Grid item xs={6}>
                 <Stack direction="row" spacing={1} alignItems="center">
                    <Dot color="primary" />
                    <Typography>Charging ({series[2]})</Typography>
                 </Stack>
              </Grid>
              <Grid item xs={6}>
                 <Stack direction="row" spacing={1} alignItems="center">
                    <Dot color="error" />
                    <Typography>Faulted ({series[3]})</Typography>
                 </Stack>
              </Grid>
           </Grid>
        </Grid>
      </Grid>
    </MainCard>
  );
}
