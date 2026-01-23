import { useState, useEffect } from 'react';
import ReactApexChart from 'react-apexcharts';

// material-ui
import {
  Grid,
  Typography,
  Stack,
  Box
} from '@mui/material';

// project-imports
import MainCard from 'components/MainCard';
import AnalyticsService from 'api/analytics';

// assets
import { Flash, BatteryCharging, MoneyRecive, Chart } from 'iconsax-reactjs';

// ==============================|| CHARGER ANALYTICS ||============================== //

export default function ChargerAnalytics() {
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState({
    totalChargers: 0,
    chargerStatus: [],
    totalEnergy: 0,
    totalRevenue: 0,
    sessionsTrend: []
  });

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      const response = await AnalyticsService.getChargerAnalytics();
      if (!response.data.error) {
        setData(response.data.data);
      }
    } catch (error) {
      console.error('Error fetching charger analytics:', error);
    } finally {
      setLoading(false);
    }
  };

  // Prepare Chart Data
  const statusChartData = {
    series: data.chargerStatus.map(s => s.count),
    options: {
      chart: { type: 'pie' },
      labels: data.chargerStatus.map(s => s._id || 'Unknown'),
      colors: ['#00e676', '#ff1744', '#2979ff', '#ff9100'],
      legend: { position: 'bottom' }
    }
  };

  const trendChartData = {
    series: [
        {
            name: 'Sessions',
            type: 'column',
            data: data.sessionsTrend.map(t => t.count)
        },
        {
            name: 'Energy (kWh)',
            type: 'line',
            data: data.sessionsTrend.map(t => t.energy)
        }
    ],
    options: {
      chart: { type: 'line', height: 350 },
      stroke: { width: [0, 4] },
      xaxis: {
        categories: data.sessionsTrend.map(t => t._id)
      },
      yaxis: [
        { title: { text: 'Sessions' } },
        { opposite: true, title: { text: 'Energy (kWh)' } }
      ],
      colors: ['#2196f3', '#ff9800']
    }
  };

  if (loading) {
    return <Typography>Loading Analytics...</Typography>;
  }

  return (
    <Grid container spacing={3}>
      <Grid item xs={12}>
        <Typography variant="h4" sx={{ mb: 2 }}>Charger Analytics</Typography>
      </Grid>

      {/* KPI Cards */}
      <Grid item xs={12} sm={6} md={3}>
        <MainCard content={false}>
            <Box sx={{ p: 2 }}>
                <Stack spacing={1}>
                    <Typography variant="subtitle1" color="textSecondary">Total Chargers</Typography>
                    <Stack direction="row" alignItems="center" spacing={2}>
                         <Flash size={32} variant="Bold" color="#ff9800"/>
                         <Typography variant="h4">{data.totalChargers}</Typography>
                    </Stack>
                </Stack>
            </Box>
        </MainCard>
      </Grid>

       <Grid item xs={12} sm={6} md={3}>
        <MainCard content={false}>
            <Box sx={{ p: 2 }}>
                <Stack spacing={1}>
                    <Typography variant="subtitle1" color="textSecondary">Total Energy Consumed</Typography>
                    <Stack direction="row" alignItems="center" spacing={2}>
                         <BatteryCharging size={32} variant="Bold" color="#2196f3"/>
                         <Typography variant="h4">{data.totalEnergy.toFixed(2)} kWh</Typography>
                    </Stack>
                </Stack>
            </Box>
        </MainCard>
      </Grid>
      
       <Grid item xs={12} sm={6} md={3}>
        <MainCard content={false}>
            <Box sx={{ p: 2 }}>
                <Stack spacing={1}>
                    <Typography variant="subtitle1" color="textSecondary">Total Revenue</Typography>
                    <Stack direction="row" alignItems="center" spacing={2}>
                         <MoneyRecive size={32} variant="Bold" color="#00e676"/>
                         <Typography variant="h4">₹{data.totalRevenue.toFixed(2)}</Typography>
                    </Stack>
                </Stack>
            </Box>
        </MainCard>
      </Grid>

       <Grid item xs={12} sm={6} md={3}>
        <MainCard content={false}>
            <Box sx={{ p: 2 }}>
                <Stack spacing={1}>
                    <Typography variant="subtitle1" color="textSecondary">Online Chargers</Typography>
                    <Stack direction="row" alignItems="center" spacing={2}>
                         <Chart size={32} variant="Bold" color="#2979ff"/>
                         <Typography variant="h4">{data.chargerStatus.find(s => s._id === 'online')?.count || 0}</Typography>
                    </Stack>
                </Stack>
            </Box>
        </MainCard>
      </Grid>

      {/* Charts */}
      <Grid item xs={12} md={8}>
        <MainCard title="Charging Trend (Last 30 Days)">
             <ReactApexChart options={trendChartData.options} series={trendChartData.series} type="line" height={350} />
        </MainCard>
      </Grid>

      <Grid item xs={12} md={4}>
         <MainCard title="Charger Status Distribution">
            <ReactApexChart options={statusChartData.options} series={statusChartData.series} type="pie" height={300} />
        </MainCard>
      </Grid>

    </Grid>
  );
}
