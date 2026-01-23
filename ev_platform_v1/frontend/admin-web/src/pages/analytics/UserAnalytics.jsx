import { useState, useEffect } from 'react';
import ReactApexChart from 'react-apexcharts';

// material-ui
import {
  Grid,
  Typography,
  Stack,
  Box,
  Tabs,
  Tab,
  TextField,
  Chip,
  Divider,
  Avatar,
  InputAdornment,
  Autocomplete
} from '@mui/material';

// project-imports
import MainCard from 'components/MainCard';
import AnalyticsService from 'api/analytics';
import UserService from 'api/user';

// assets
import { Profile2User, UserTick, UserMinus, ShieldSecurity, SearchNormal1, Calendar, BatteryCharging, Wallet, Timer1 } from 'iconsax-reactjs';

// ==============================|| USER ANALYTICS ||============================== //

export default function UserAnalytics() {
  const [loading, setLoading] = useState(true);
  const [tabValue, setTabValue] = useState(0); // 0: Overview, 1: Individual
  const [data, setData] = useState({
    totalUsers: 0,
    usersByRole: [],
    userGrowth: [],
    userStatus: []
  });

  // Individual User State
  const [searchLoading, setSearchLoading] = useState(false);
  const [selectedUserStats, setSelectedUserStats] = useState(null);
  const [searchError, setSearchError] = useState('');
  
  const [allUsers, setAllUsers] = useState([]);
  const [selectedUser, setSelectedUser] = useState(null);

  useEffect(() => {
    fetchData();
  }, []);
  
  useEffect(() => {
    if (tabValue === 1 && allUsers.length === 0) {
        fetchAllUsers();
    }
  }, [tabValue]);

  const fetchAllUsers = async () => {
    try {
        const response = await UserService.getAllUsers(1, 1000);
        if (!response.data.error) {
            setAllUsers(response.data.data);
        }
    } catch (error) {
        console.error('Error fetching all users:', error);
    }
  };

  const fetchData = async () => {
    try {
      const response = await AnalyticsService.getUserAnalytics();
      if (!response.data.error) {
        setData(response.data.data);
      }
    } catch (error) {
      console.error('Error fetching user analytics:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSearchUser = async (user = null) => {
    if (!user) return;
    const query = user.user_id;
    
    setSearchLoading(true);
    setSearchError('');
    setSelectedUserStats(null);

    try {
      const response = await AnalyticsService.getUserDetailAnalytics(query);
      if (!response.data.error) {
        setSelectedUserStats(response.data.data);
      }
    } catch (error) {
      console.error('Error fetching user details:', error);
      setSearchError(error.response?.data?.message || 'User not found');
    } finally {
      setSearchLoading(false);
    }
  };
  
  const handleUserSelect = (event, newValue) => {
      setSelectedUser(newValue);
      if (newValue) {
          handleSearchUser(newValue);
      }
  };

  // Prepare Chart Data for Overview
  const roleChartData = {
    series: data.usersByRole.map(r => r.count),
    options: {
      chart: { type: 'pie' },
      labels: data.usersByRole.map(r => {
        const roles = { 1: 'Super Admin', 2: 'Admin', 3: 'Station Manager', 4: 'Support', 5: 'User' };
        return roles[r._id] || `Role ${r._id}`;
      }),
      colors: ['#00C49F', '#FFBB28', '#FF8042', '#0088FE', '#8884d8'],
      legend: { position: 'bottom' }
    }
  };

  const statusChartData = {
    series: data.userStatus.map(s => s.count),
    options: {
      chart: { type: 'donut' },
      labels: data.userStatus.map(s => s._id ? 'Active' : 'Blocked'),
      colors: ['#00e676', '#ff1744'],
      legend: { position: 'bottom' }
    }
  };

  // Calculate Cumulative Growth
  const calculateCumulative = () => {
    let sum = 0;
    return data.userGrowth.map(g => {
      sum += g.count;
      return sum;
    });
  };

  const growthChartData = {
    series: [
      {
        name: 'New Users',
        type: 'column',
        data: data.userGrowth.map(g => g.count)
      },
      {
        name: 'Cumulative Growth',
        type: 'line',
        data: calculateCumulative()
      }
    ],
    options: {
      chart: { type: 'line', height: 350 },
      stroke: { width: [0, 4] },
      xaxis: {
        categories: data.userGrowth.map(g => g._id)
      },
      yaxis: [
        { title: { text: 'New Users' } },
        { opposite: true, title: { text: 'Cumulative Users' } }
      ],
      colors: ['#2196f3', '#ff9800'],
      legend: { position: 'bottom' }
    }
  };

  // Prepare Chart Data for Individual User
  const userUsageChartData = selectedUserStats ? {
    series: [
        { name: 'Sessions', type: 'column', data: selectedUserStats.history.map(h => h.sessions) },
        { name: 'Energy (kWh)', type: 'line', data: selectedUserStats.history.map(h => h.energy) }
    ],
    options: {
        chart: { type: 'line', height: 350 },
        stroke: { width: [0, 3] },
        xaxis: { categories: selectedUserStats.history.map(h => h._id) },
        colors: ['#2196f3', '#00e676']
    }
  } : null;

  if (loading) {
    return <Typography>Loading Analytics...</Typography>;
  }

  return (
    <Grid container spacing={3}>
      <Grid item xs={12}>
        <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
            <Tabs value={tabValue} onChange={(e, val) => setTabValue(val)}>
                <Tab label="Platform Overview" />
                <Tab label="Individual Insights" />
            </Tabs>
        </Box>
      </Grid>

      {/* TAB 1: OVERVIEW */}
      {tabValue === 0 && (
        <>
            {/* KPI Cards */}
            <Grid item xs={12}>
                <Grid container spacing={3}>
                    <Grid item xs={12} sm={6} md={3}>
                        <MainCard content={false} sx={{ bgcolor: 'primary.lighter' }}>
                            <Box sx={{ p: 2 }}>
                                <Stack spacing={1}>
                                    <Typography variant="subtitle1" color="textSecondary">Total Users</Typography>
                                    <Stack direction="row" alignItems="center" spacing={2}>
                                        <Profile2User size={32} variant="Bold" color="#2196f3"/>
                                        <Typography variant="h4">{data.totalUsers}</Typography>
                                    </Stack>
                                </Stack>
                            </Box>
                        </MainCard>
                    </Grid>

                    <Grid item xs={12} sm={6} md={3}>
                        <MainCard content={false} sx={{ bgcolor: 'success.lighter' }}>
                            <Box sx={{ p: 2 }}>
                                <Stack spacing={1}>
                                    <Typography variant="subtitle1" color="textSecondary">Active Users</Typography>
                                    <Stack direction="row" alignItems="center" spacing={2}>
                                        <UserTick size={32} variant="Bold" color="#00e676"/>
                                        <Typography variant="h4">{data.userStatus.find(s => s._id)?.count || 0}</Typography>
                                    </Stack>
                                </Stack>
                            </Box>
                        </MainCard>
                    </Grid>
                    
                    <Grid item xs={12} sm={6} md={3}>
                        <MainCard content={false} sx={{ bgcolor: 'error.lighter' }}>
                            <Box sx={{ p: 2 }}>
                                <Stack spacing={1}>
                                    <Typography variant="subtitle1" color="textSecondary">Blocked Users</Typography>
                                    <Stack direction="row" alignItems="center" spacing={2}>
                                        <UserMinus size={32} variant="Bold" color="#ff1744"/>
                                        <Typography variant="h4">{data.userStatus.find(s => !s._id)?.count || 0}</Typography>
                                    </Stack>
                                </Stack>
                            </Box>
                        </MainCard>
                    </Grid>

                    <Grid item xs={12} sm={6} md={3}>
                        <MainCard content={false} sx={{ bgcolor: 'warning.lighter' }}>
                            <Box sx={{ p: 2 }}>
                                <Stack spacing={1}>
                                    <Typography variant="subtitle1" color="textSecondary">Admins</Typography>
                                    <Stack direction="row" alignItems="center" spacing={2}>
                                        <ShieldSecurity size={32} variant="Bold" color="#FFBB28"/>
                                        <Typography variant="h4">{data.usersByRole.find(r => r._id === 2)?.count || 0}</Typography>
                                    </Stack>
                                </Stack>
                            </Box>
                        </MainCard>
                    </Grid>
                </Grid>
            </Grid>

            {/* Charts */}
            <Grid item xs={12}>
                <MainCard title="User Growth (Last 6 Months)">
                    <ReactApexChart options={growthChartData.options} series={growthChartData.series} type="line" height={350} />
                </MainCard>
            </Grid>

            <Grid item xs={12} md={6}>
                <MainCard title="User Roles Distribution">
                    <ReactApexChart options={roleChartData.options} series={roleChartData.series} type="pie" height={300} />
                </MainCard>
            </Grid>

            <Grid item xs={12} md={6}>
                <MainCard title="User Status">
                    <ReactApexChart options={statusChartData.options} series={statusChartData.series} type="donut" height={300} />
                </MainCard>
            </Grid>
        </>
      )}

      {/* TAB 2: INDIVIDUAL INSIGHTS */}
      {tabValue === 1 && (
        <>
            <Grid item xs={12}>
                <MainCard sx={{ p: 2 }}>
                    <Stack spacing={2}>
                        <Autocomplete
                            fullWidth
                            options={allUsers}
                            getOptionLabel={(option) => `${option.username} (${option.email_id})`}
                            value={selectedUser}
                            onChange={handleUserSelect}
                            renderInput={(params) => (
                                <TextField
                                    {...params}
                                    placeholder="Select User to view details..."
                                    InputProps={{
                                        ...params.InputProps,
                                        startAdornment: (
                                            <>
                                                <InputAdornment position="start">
                                                    <SearchNormal1 size={20} />
                                                </InputAdornment>
                                                {params.InputProps.startAdornment}
                                            </>
                                        ),
                                    }}
                                />
                            )}
                            renderOption={(props, option) => {
                                const { key, ...otherProps } = props;
                                return (
                                <Box component="li" key={key} {...otherProps}>
                                    <Stack direction="row" spacing={2} alignItems="center">
                                        <Avatar sx={{ width: 32, height: 32, bgcolor: 'primary.lighter', color: 'primary.main', fontSize: '0.875rem' }}>
                                            {option.username.charAt(0).toUpperCase()}
                                        </Avatar>
                                        <Stack>
                                            <Typography variant="subtitle2">{option.username}</Typography>
                                            <Typography variant="caption" color="textSecondary">{option.email_id}</Typography>
                                        </Stack>
                                    </Stack>
                                </Box>
                                );
                            }}
                        />
                    </Stack>
                    {searchError && (
                        <Typography color="error" sx={{ mt: 2 }}>
                            {searchError}
                        </Typography>
                    )}
                </MainCard>
            </Grid>

            {searchLoading && (
                <Grid item xs={12}>
                    <Typography textAlign="center" sx={{ py: 3 }}>Loading user details...</Typography>
                </Grid>
            )}

            {!searchLoading && selectedUserStats && (
                <>
                    {/* User Profile Card */}
                    <Grid item xs={12} md={4}>
                        <MainCard title="User Profile">
                            <Stack spacing={3} alignItems="center">
                                <Avatar 
                                    sx={{ width: 80, height: 80, bgcolor: 'primary.main', fontSize: '2rem' }}
                                >
                                    {selectedUserStats.user.username?.charAt(0).toUpperCase()}
                                </Avatar>
                                <Typography variant="h5">{selectedUserStats.user.username}</Typography>
                                <Chip 
                                    label={selectedUserStats.user.status ? "Active" : "Blocked"} 
                                    color={selectedUserStats.user.status ? "success" : "error"} 
                                />
                                
                                <Divider sx={{ width: '100%' }} />
                                
                                <Stack spacing={2} width="100%">
                                    <Stack direction="row" justifyContent="space-between">
                                        <Typography color="textSecondary">User ID</Typography>
                                        <Typography variant="subtitle1">{selectedUserStats.user.user_id}</Typography>
                                    </Stack>
                                    <Stack direction="row" justifyContent="space-between">
                                        <Typography color="textSecondary">Email</Typography>
                                        <Typography variant="subtitle1">{selectedUserStats.user.email}</Typography>
                                    </Stack>
                                    <Stack direction="row" justifyContent="space-between">
                                        <Typography color="textSecondary">Phone</Typography>
                                        <Typography variant="subtitle1">{selectedUserStats.user.phone_no || 'N/A'}</Typography>
                                    </Stack>
                                    <Stack direction="row" justifyContent="space-between">
                                        <Typography color="textSecondary">Role</Typography>
                                        <Typography variant="subtitle1">
                                            {{ 1: 'Super Admin', 2: 'Admin', 3: 'Station Manager', 4: 'Support', 5: 'User' }[selectedUserStats.user.role_id] || 'User'}
                                        </Typography>
                                    </Stack>
                                    <Stack direction="row" justifyContent="space-between">
                                        <Typography color="textSecondary">Wallet Balance</Typography>
                                        <Typography variant="subtitle1">₹{selectedUserStats.user.wallet_bal?.toFixed(2) || '0.00'}</Typography>
                                    </Stack>
                                    <Stack direction="row" justifyContent="space-between">
                                        <Typography color="textSecondary">RFID Tag</Typography>
                                        <Typography variant="subtitle1">{selectedUserStats.user.rfid_tag || 'Not Assigned'}</Typography>
                                    </Stack>
                                    <Stack direction="row" justifyContent="space-between">
                                        <Typography color="textSecondary">Joined</Typography>
                                        <Typography variant="subtitle1">{new Date(selectedUserStats.user.created_at).toLocaleDateString()}</Typography>
                                    </Stack>
                                </Stack>
                            </Stack>
                        </MainCard>
                    </Grid>

                    {/* Stats & Charts */}
                    <Grid item xs={12} md={8}>
                        <Grid container spacing={3}>
                            {/* Stats Cards */}
                            <Grid item xs={12} sm={6} md={3}>
                                <MainCard content={false} sx={{ bgcolor: 'primary.lighter' }}>
                                    <Box sx={{ p: 2 }}>
                                        <Stack spacing={1} alignItems="center">
                                            <Timer1 size={24} color="#2196f3"/>
                                            <Typography variant="h4">{selectedUserStats.stats.totalSessions}</Typography>
                                            <Typography variant="body2" color="textSecondary">Total Sessions</Typography>
                                        </Stack>
                                    </Box>
                                </MainCard>
                            </Grid>
                            <Grid item xs={12} sm={6} md={3}>
                                <MainCard content={false} sx={{ bgcolor: 'success.lighter' }}>
                                    <Box sx={{ p: 2 }}>
                                        <Stack spacing={1} alignItems="center">
                                            <BatteryCharging size={24} color="#00e676"/>
                                            <Typography variant="h4">{selectedUserStats.stats.totalEnergy.toFixed(1)} kWh</Typography>
                                            <Typography variant="body2" color="textSecondary">Total Energy</Typography>
                                        </Stack>
                                    </Box>
                                </MainCard>
                            </Grid>
                            <Grid item xs={12} sm={6} md={3}>
                                <MainCard content={false} sx={{ bgcolor: 'warning.lighter' }}>
                                    <Box sx={{ p: 2 }}>
                                        <Stack spacing={1} alignItems="center">
                                            <Wallet size={24} color="#ffab00"/>
                                            <Typography variant="h4">₹{selectedUserStats.stats.totalSpent.toFixed(2)}</Typography>
                                            <Typography variant="body2" color="textSecondary">Total Spent</Typography>
                                        </Stack>
                                    </Box>
                                </MainCard>
                            </Grid>
                             <Grid item xs={12} sm={6} md={3}>
                                <MainCard content={false} sx={{ bgcolor: 'error.lighter' }}>
                                    <Box sx={{ p: 2 }}>
                                        <Stack spacing={1} alignItems="center">
                                            <Calendar size={24} color="#ff5252"/>
                                            <Typography variant="h6">{selectedUserStats.stats.lastSessionDate ? new Date(selectedUserStats.stats.lastSessionDate).toLocaleDateString() : 'Never'}</Typography>
                                            <Typography variant="body2" color="textSecondary">Last Session</Typography>
                                        </Stack>
                                    </Box>
                                </MainCard>
                            </Grid>

                            {/* Usage Chart */}
                            <Grid item xs={12}>
                                <MainCard title="Usage History (Last 6 Months)">
                                    {selectedUserStats.history.length > 0 ? (
                                        <ReactApexChart options={userUsageChartData.options} series={userUsageChartData.series} type="line" height={350} />
                                    ) : (
                                        <Box sx={{ p: 3, textAlign: 'center' }}>
                                            <Typography color="textSecondary">No usage history available for this period.</Typography>
                                        </Box>
                                    )}
                                </MainCard>
                            </Grid>
                        </Grid>
                    </Grid>
                </>
            )}
        </>
      )}

    </Grid>
  );
}
