import { Link } from 'react-router-dom';

// material-ui
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Grid from '@mui/material/Grid';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';

// project-imports
import MainCard from 'components/MainCard';

// ==============================|| ERROR 404 ||============================== //

export default function Error404() {
  return (
    <MainCard content={false} sx={{ p: 3, m: 3, minHeight: 'calc(100vh - 48px)' }}>
      <Grid
        container
        alignItems="center"
        justifyContent="center"
        spacing={3}
        sx={{ minHeight: 'calc(100vh - 96px)' }}
      >
        <Grid item xs={12}>
          <Stack spacing={2} justifyContent="center" alignItems="center">
            <Typography variant="h1">404</Typography>
            <Typography variant="h4">Page Not Found</Typography>
            <Typography variant="body1" color="textSecondary">
              The page you are looking for was not found.
            </Typography>
            <Button component={Link} to="/" variant="contained">
              Back to Home
            </Button>
          </Stack>
        </Grid>
      </Grid>
    </MainCard>
  );
}
