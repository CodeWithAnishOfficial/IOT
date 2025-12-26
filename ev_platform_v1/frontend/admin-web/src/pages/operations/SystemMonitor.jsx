import { useState } from 'react';

// material-ui
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import CircularProgress from '@mui/material/CircularProgress';

// project-imports
import MainCard from 'components/MainCard';

// ==============================|| SYSTEM MONITOR ||============================== //

export default function SystemMonitor() {
  const [loading, setLoading] = useState(true);

  // The URL for the Grafana dashboard. 
  // In a production environment, this should be an environment variable.
  // Assuming Grafana is running on localhost:3003 as per docker-compose.
  const GRAFANA_URL = 'http://localhost:3003/?orgId=1'; 

  const handleLoad = () => {
    setLoading(false);
  };

  return (
    <MainCard title="System Health & Metrics (Grafana)">
      <Box sx={{ position: 'relative', width: '100%', height: 'calc(100vh - 200px)', minHeight: '600px' }}>
        {loading && (
          <Box 
            sx={{ 
              position: 'absolute', 
              top: '50%', 
              left: '50%', 
              transform: 'translate(-50%, -50%)',
              zIndex: 1 
            }}
          >
            <CircularProgress />
            <Typography variant="body2" sx={{ mt: 1 }}>Loading Dashboard...</Typography>
          </Box>
        )}
        <iframe
          src={GRAFANA_URL}
          width="100%"
          height="100%"
          frameBorder="0"
          onLoad={handleLoad}
          title="Grafana Dashboard"
          style={{ 
            borderRadius: '4px',
            opacity: loading ? 0 : 1,
            transition: 'opacity 0.3s ease-in-out'
          }}
        />
        <Typography variant="caption" sx={{ mt: 1, display: 'block', color: 'text.secondary' }}>
          * Ensure you are logged into Grafana (admin/admin) or have configured anonymous access.
        </Typography>
      </Box>
    </MainCard>
  );
}
