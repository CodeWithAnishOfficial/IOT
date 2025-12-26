import { useState, useEffect } from 'react';

// material-ui
import List from '@mui/material/List';
import ListItem from '@mui/material/ListItem';
import ListItemAvatar from '@mui/material/ListItemAvatar';
import ListItemText from '@mui/material/ListItemText';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Chip from '@mui/material/Chip';

// project-imports
import Avatar from 'components/@extended/Avatar';
import MainCard from 'components/MainCard';
import DashboardService from 'api/dashboard';

// assets
import { Flash } from 'iconsax-reactjs';

// ==============================|| DATA WIDGET - RECENT ACTIVITY ||============================== //

export default function Transactions() {
  const [sessions, setSessions] = useState([]);

  useEffect(() => {
    fetchRecentActivity();
  }, []);

  const fetchRecentActivity = async () => {
    try {
      const response = await DashboardService.getRecentActivity();
      if (!response.data.error) {
        setSessions(response.data.data);
      }
    } catch (error) {
      console.error('Error fetching recent activity:', error);
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'active': return 'success';
      case 'completed': return 'primary';
      case 'faulted': return 'error';
      default: return 'secondary';
    }
  };

  return (
    <MainCard content={false} sx={{ height: '100%' }}>
      <Box sx={{ p: 3, pb: 1 }}>
        <Typography variant="h5">Transaction History</Typography>
      </Box>
      <Box sx={{ width: '100%', overflowX: 'auto' }}>
        <List disablePadding sx={{ '& .MuiListItem-root': { px: 3, py: 1.5 } }}>
          {sessions.map((session, index) => (
            <ListItem
              key={session._id || index}
              divider={index < sessions.length - 1}
              secondaryAction={
                <Stack sx={{ gap: 0.5, alignItems: 'flex-end' }}>
                  <Typography variant="subtitle1">{session.total_energy.toFixed(2)} kWh</Typography>
                  <Chip 
                    label={session.status} 
                    color={getStatusColor(session.status)} 
                    size="small" 
                    variant="light" 
                  />
                </Stack>
              }
            >
              <ListItemAvatar>
                <Avatar
                  variant="rounded"
                  type="outlined"
                  color="secondary"
                  sx={{ color: 'secondary.darker', borderColor: 'secondary.light', fontWeight: 600 }}
                >
                  <Flash size={20} variant="Bold"/>
                </Avatar>
              </ListItemAvatar>
              <ListItemText
                primary={<Typography variant="subtitle1">{session.station_id?.name || 'Unknown Station'}</Typography>}
                secondary={
                  <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                    {session.user_id?.username || 'Guest'} • {new Date(session.createdAt).toLocaleString()}
                  </Typography>
                }
              />
            </ListItem>
          ))}
          {sessions.length === 0 && (
            <ListItem>
              <ListItemText primary="No recent activity found" />
            </ListItem>
          )}
        </List>
      </Box>
    </MainCard>
  );
}
