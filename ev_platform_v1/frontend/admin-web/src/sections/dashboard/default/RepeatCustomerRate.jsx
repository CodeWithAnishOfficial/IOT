import { useState, useEffect } from 'react';

// material-ui
import Chip from '@mui/material/Chip';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';

// project-imports
import WeeklyAnalyticsChart from './RepeatCustomerChart'; // Kept filename but content changed
import MainCard from 'components/MainCard';
import DashboardService from 'api/dashboard';

// ==============================|| CHART - WEEKLY ANALYTICS ||============================== //

export default function WeeklyAnalytics() {
  const [series, setSeries] = useState([]);
  const [categories, setCategories] = useState([]);
  const [totalRevenue, setTotalRevenue] = useState(0);

  useEffect(() => {
    fetchAnalytics();
  }, []);

  const fetchAnalytics = async () => {
    try {
      const response = await DashboardService.getAnalytics();
      if (!response.data.error) {
        const { revenue_chart, energy_chart } = response.data.data;
        
        // Process data for chart
        // Assuming sorted by date from backend
        const dates = revenue_chart.map(d => d._id); // ["2023-10-01", ...]
        const revenueData = revenue_chart.map(d => d.revenue);
        // Match energy data to dates (simple assumption: data exists for same days or we need to merge)
        // For simplicity, we'll map energy to the same dates if possible, or just use revenue dates
        // A more robust solution would be to generate a date range and fill 0s.
        
        // Let's just use what we have, assuming reasonably consistent data or just plot revenue for now if energy is sparse.
        // Actually, let's map energy to the revenue dates
        const energyData = dates.map(date => {
            const entry = energy_chart.find(e => e._id === date);
            return entry ? (entry.energy / 1000).toFixed(2) : 0; // Convert to kWh
        });

        setCategories(dates.map(d => new Date(d).toLocaleDateString(undefined, { weekday: 'short' })));
        setSeries([
            { name: 'Revenue ($)', data: revenueData },
            { name: 'Energy (kWh)', data: energyData }
        ]);
        
        setTotalRevenue(revenueData.reduce((a, b) => a + b, 0));
      }
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <MainCard>
      <Stack direction="row" sx={{ gap: 1, alignItems: 'center', justifyContent: 'space-between' }}>
        <Typography variant="h5">Weekly Analytics</Typography>
      </Stack>
      <Stack direction="row" sx={{ gap: 0.5, alignItems: 'center', justifyContent: 'flex-end', mt: 1 }}>
        <Typography variant="subtitle1">${totalRevenue.toLocaleString()}</Typography>
        <Chip color="primary" variant="filled" label="Last 7 Days" size="small" sx={{ borderRadius: 1 }} />
      </Stack>
      <WeeklyAnalyticsChart data={series} categories={categories} />
    </MainCard>
  );
}
