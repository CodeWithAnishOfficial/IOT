import { useState, useEffect } from 'react';

// material-ui
import { useTheme } from '@mui/material/styles';
import Grid from '@mui/material/Grid';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';

// project-imports
import EcommerceDataCard from 'components/cards/statistics/EcommerceDataCard';
import { GRID_COMMON_SPACING } from 'config';
import DashboardService from 'api/dashboard';

import WelcomeBanner from 'sections/dashboard/default/WelcomeBanner';
import ProjectRelease from 'sections/dashboard/default/ProjectRelease';
import EcommerceDataChart from 'sections/dashboard/default/EcommerceDataChart';
import TotalIncome from 'sections/dashboard/default/TotalIncome';
import RepeatCustomerRate from 'sections/dashboard/default/RepeatCustomerRate';
import ProjectOverview from 'sections/dashboard/default/ProjectOverview';
import Transactions from 'sections/dashboard/default/Transactions';
import AssignUsers from 'sections/dashboard/default/AssignUsers';

// assets
import { ArrowDown, ArrowUp, Book, Calendar, CloudChange, Wallet3, Flash, Building } from 'iconsax-reactjs';

// ==============================|| DASHBOARD - DEFAULT ||============================== //

export default function DashboardDefault() {
  const theme = useTheme();
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

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
      console.error('Error fetching dashboard stats:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Grid container spacing={GRID_COMMON_SPACING}>
      <Grid size={12}>
        <WelcomeBanner />
      </Grid>
      {/* row 1 */}
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <EcommerceDataCard
          title="Total Revenue"
          count={stats ? `$${stats.financials.total_revenue.toLocaleString()}` : '$0'}
          iconPrimary={<Wallet3 />}
        >
          <EcommerceDataChart color={theme.palette.primary.main} />
        </EcommerceDataCard>
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <EcommerceDataCard
          title="Total Energy"
          count={stats ? `${stats.financials.total_energy_kwh.toLocaleString()} kWh` : '0 kWh'}
          color="warning"
          iconPrimary={<CloudChange />}
        >
          <EcommerceDataChart color={theme.palette.warning.dark} />
        </EcommerceDataCard>
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <EcommerceDataCard
          title="Active Sessions"
          count={stats ? stats.sessions.active : 0}
          color="success"
          iconPrimary={<Calendar />}
        >
          <EcommerceDataChart color={theme.palette.success.darker} />
        </EcommerceDataCard>
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <EcommerceDataCard
          title="Stations Online"
          count={stats ? `${stats.stations.online} / ${stats.stations.total}` : '0 / 0'}
          color="error"
          iconPrimary={<Book />}
        >
          <EcommerceDataChart color={theme.palette.error.dark} />
        </EcommerceDataCard>
      </Grid>
      {/* row 2 */}
      <Grid size={{ xs: 12, md: 8, lg: 9 }}>
        <Grid container spacing={GRID_COMMON_SPACING}>
          <Grid size={12}>
            <RepeatCustomerRate />
          </Grid>
          <Grid size={12}>
            <ProjectOverview />
          </Grid>
        </Grid>
      </Grid>
      <Grid size={{ xs: 12, md: 4, lg: 3 }}>
        <Stack sx={{ gap: GRID_COMMON_SPACING }}>
          <ProjectRelease />
          <AssignUsers />
        </Stack>
      </Grid>
      {/* row 3 */}
      <Grid size={{ xs: 12, md: 6 }}>
        <TotalIncome />
      </Grid>
      <Grid size={{ xs: 12, md: 6 }}>
        <Transactions />
      </Grid>
    </Grid>
  );
}
