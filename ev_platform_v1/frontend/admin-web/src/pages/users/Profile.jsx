import { useState, useContext, useEffect } from 'react';

// material-ui
import {
  Grid,
  Stack,
  Typography,
  TextField,
  Button,
  Divider,
  Avatar,
  CardContent,
  Alert,
  Tabs,
  Tab,
  Box,
  InputAdornment,
  IconButton
} from '@mui/material';

// project-imports
import MainCard from 'components/MainCard';
import { AuthContext } from 'contexts/AuthContext';
import ProfileService from 'api/profile';

// assets
import { Eye, EyeSlash, Profile, Edit } from 'iconsax-reactjs';
import avatar1 from 'assets/images/users/avatar-6.png';

function TabPanel({ children, value, index, ...other }) {
  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`simple-tabpanel-${index}`}
      aria-labelledby={`simple-tab-${index}`}
      {...other}
    >
      {value === index && (
        <Box sx={{ pt: 3 }}>
          {children}
        </Box>
      )}
    </div>
  );
}

export default function UserProfile() {
  const { user, dispatch } = useContext(AuthContext); // Assuming dispatch or setAuth is available to update context
  const [profileData, setProfileData] = useState(null);
  const [value, setValue] = useState(0);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(null);
  const [error, setError] = useState(null);
  const [showPassword, setShowPassword] = useState(false);

  const [formData, setFormData] = useState({
    username: '',
    email_id: '',
    phone_no: '',
    role_id: '',
    password: ''
  });

  useEffect(() => {
    if (user) {
        fetchProfileData();
    }
  }, [user]);

  const fetchProfileData = async () => {
    try {
        const id = user._id || user.id || user.user_id;
        if (!id) return;
        
        const response = await ProfileService.getProfile(id);
        if (!response.data.error) {
            const data = response.data.data;
            setProfileData(data);
            setFormData({
                username: data.username || '',
                email_id: data.email_id || '',
                phone_no: data.phone_no || '',
                role_id: data.role_id || '',
                password: ''
            });
        }
    } catch (error) {
        console.error('Error fetching profile:', error);
    }
  };

  const handleChange = (event, newValue) => {
    setValue(newValue);
    setSuccess(null);
    setError(null);
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async () => {
    setLoading(true);
    setError(null);
    setSuccess(null);

    try {
      const payload = {
        username: formData.username,
        email_id: formData.email_id,
        phone_no: formData.phone_no
      };

      if (formData.password) {
        payload.password = formData.password;
      }

      const id = user._id || user.id || user.user_id;
      const response = await ProfileService.updateProfile(id, payload);

      if (!response.data.error) {
        setSuccess('Profile updated successfully');
        // Optionally refresh profile data
        fetchProfileData();
      }
    } catch (err) {
      console.error(err);
      setError(err.response?.data?.message || 'Error updating profile');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Grid container spacing={3}>
      <Grid item xs={12} md={4}>
        <MainCard>
          <Stack spacing={2.5} alignItems="center">
            <Avatar alt="User Avatar" src={avatar1} sx={{ width: 100, height: 100 }} />
            <Stack spacing={0.5} alignItems="center">
              <Typography variant="h5">{profileData?.username || user?.username || 'User'}</Typography>
              <Typography variant="body2" color="secondary">
                {user?.role || 'Administrator'}
              </Typography>
            </Stack>
          </Stack>
        </MainCard>
      </Grid>
      <Grid item xs={12} md={8}>
        <MainCard>
          <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
            <Tabs value={value} onChange={handleChange} aria-label="profile tabs">
              <Tab label="Profile Details" icon={<Profile />} iconPosition="start" />
              <Tab label="Edit Profile" icon={<Edit />} iconPosition="start" />
            </Tabs>
          </Box>
          
          <TabPanel value={value} index={0}>
            <Stack spacing={2.5}>
              <Grid container spacing={3}>
                <Grid item xs={12}>
                  <Stack spacing={0.5}>
                    <Typography color="secondary">Username</Typography>
                    <Typography variant="subtitle1">{profileData?.username || user?.username}</Typography>
                  </Stack>
                </Grid>
                <Grid item xs={12} md={6}>
                  <Stack spacing={0.5}>
                    <Typography color="secondary">Email</Typography>
                    <Typography variant="subtitle1">{profileData?.email_id || user?.email_id}</Typography>
                  </Stack>
                </Grid>
                <Grid item xs={12} md={6}>
                  <Stack spacing={0.5}>
                    <Typography color="secondary">Phone Number</Typography>
                    <Typography variant="subtitle1">{profileData?.phone_no || user?.phone_no || 'N/A'}</Typography>
                  </Stack>
                </Grid>

              </Grid>
            </Stack>
          </TabPanel>

          <TabPanel value={value} index={1}>
             <Stack spacing={3}>
                {success && <Alert severity="success">{success}</Alert>}
                {error && <Alert severity="error">{error}</Alert>}

                <Grid container spacing={3}>
                   <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="Username"
                      name="username"
                      value={formData.username}
                      onChange={handleInputChange}
                    />
                  </Grid>
                  <Grid item xs={12} md={6}>
                    <TextField
                      fullWidth
                      label="Email"
                      name="email_id"
                      value={formData.email_id}
                      onChange={handleInputChange}
                      disabled
                    />
                  </Grid>
                  <Grid item xs={12} md={6}>
                    <TextField
                      fullWidth
                      label="Phone Number"
                      name="phone_no"
                      value={formData.phone_no}
                      onChange={handleInputChange}
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="New Password"
                      name="password"
                      type={showPassword ? 'text' : 'password'}
                      value={formData.password}
                      onChange={handleInputChange}
                      helperText="Leave blank to keep current password"
                      InputProps={{
                        endAdornment: (
                          <InputAdornment position="end">
                            <IconButton
                              onClick={() => setShowPassword(!showPassword)}
                              edge="end"
                            >
                              {showPassword ? <Eye /> : <EyeSlash />}
                            </IconButton>
                          </InputAdornment>
                        )
                      }}
                    />
                  </Grid>
                </Grid>
                
                <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
                  <Button variant="contained" onClick={handleSubmit} disabled={loading}>
                    {loading ? 'Updating...' : 'Save Changes'}
                  </Button>
                </Box>
             </Stack>
          </TabPanel>
        </MainCard>
      </Grid>
    </Grid>
  );
}
