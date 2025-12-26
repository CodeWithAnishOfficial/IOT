import { useState, useEffect } from 'react';
import { useTheme } from '@mui/material/styles';

// material-ui
import {
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  CircularProgress,
  Box,
  IconButton,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Switch,
  Typography,
  Stack,
  Tooltip,
  Grid,
  Divider
} from '@mui/material';

// icons
import { Edit, Trash, Add, CloseCircle, Eye, User, Sms, Call, ShieldSecurity, Wallet, ScanBarcode } from 'iconsax-reactjs';

// project-imports
import MainCard from 'components/MainCard';
import UserService from 'api/user';

// Roles mapping
const ROLES = [
  { id: 1, name: 'Super Admin' },
  { id: 2, name: 'Admin' },
  { id: 3, name: 'Station Manager' },
  { id: 4, name: 'Support' },
  { id: 5, name: 'User' }
];

export default function UsersList() {
  const theme = useTheme();
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [open, setOpen] = useState(false);
  const [viewOpen, setViewOpen] = useState(false);
  const [isEdit, setIsEdit] = useState(false);
  const [selectedUser, setSelectedUser] = useState(null);

  // Form State
  const [formData, setFormData] = useState({
    username: '',
    email_id: '',
    phone_no: '',
    role_id: 5,
    rfid_tag: '',
    password: '',
    status: true,
    wallet_bal: 0
  });

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      const response = await UserService.getAllUsers();
      if (!response.data.error) {
        setUsers(response.data.data);
      }
    } catch (error) {
      console.error('Error fetching users:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleOpen = (user = null) => {
    if (user) {
      setIsEdit(true);
      setSelectedUser(user);
      setFormData({
        username: user.username,
        email_id: user.email_id,
        phone_no: user.phone_no || '',
        role_id: user.role_id,
        rfid_tag: user.rfid_tag || '',
        status: user.status,
        wallet_bal: user.wallet_bal || 0,
        password: '' // Don't fill password on edit
      });
    } else {
      setIsEdit(false);
      setSelectedUser(null);
      setFormData({
        username: '',
        email_id: '',
        phone_no: '',
        role_id: 5,
        rfid_tag: '',
        password: '',
        status: true,
        wallet_bal: 0
      });
    }
    setOpen(true);
  };

  const handleClose = () => {
    setOpen(false);
    setViewOpen(false);
  };

  const handleViewOpen = (user) => {
    setSelectedUser(user);
    setViewOpen(true);
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async () => {
    try {
      if (isEdit) {
        // Only include password if it's not empty
        const updateData = { ...formData };
        if (!updateData.password) delete updateData.password;
        
        await UserService.updateUser(selectedUser.user_id, updateData);
      } else {
        await UserService.createUser(formData);
      }
      fetchUsers();
      handleClose();
    } catch (error) {
      console.error('Error saving user:', error);
      alert(error.response?.data?.message || 'Error saving user');
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this user?')) {
      try {
        await UserService.deleteUser(id);
        fetchUsers();
      } catch (error) {
        console.error('Error deleting user:', error);
      }
    }
  };

  const handleToggleStatus = async (user) => {
    try {
      await UserService.toggleUserStatus(user.user_id, !user.status);
      fetchUsers();
    } catch (error) {
      console.error('Error toggling status:', error);
    }
  };

  const getRoleName = (roleId) => {
    const role = ROLES.find(r => r.id === roleId);
    return role ? role.name : roleId;
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <MainCard title="Users" secondary={
      <Button variant="contained" startIcon={<Add />} onClick={() => handleOpen()}>
        Add User
      </Button>
    }>
      <TableContainer component={Paper} sx={{ boxShadow: 'none', border: '1px solid', borderColor: 'divider' }}>
        <Table sx={{ minWidth: 650 }} aria-label="users table">
          <TableHead>
            <TableRow>
              <TableCell>User ID</TableCell>
              <TableCell>Username</TableCell>
              <TableCell>Email</TableCell>
              <TableCell>Role</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Wallet</TableCell>
              <TableCell align="right">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {users.map((user, index) => (
              <TableRow key={user.user_id} sx={{ backgroundColor: index % 2 !== 0 ? theme.palette.secondary.lighter : 'inherit' }}>
                <TableCell>{user.user_id}</TableCell>
                <TableCell>
                  <Typography variant="subtitle1">{user.username}</Typography>
                  <Typography variant="caption" color="textSecondary">{user.phone_no}</Typography>
                </TableCell>
                <TableCell>{user.email_id}</TableCell>
                <TableCell>{getRoleName(user.role_id)}</TableCell>
                <TableCell>
                  <Chip 
                    label={user.status ? 'Active' : 'Blocked'} 
                    color={user.status ? 'success' : 'error'} 
                    size="small"
                    onClick={() => handleToggleStatus(user)}
                    clickable
                  />
                </TableCell>
                <TableCell>₹{user.wallet_bal}</TableCell>
                <TableCell align="right">
                  <Tooltip title="View Details">
                    <IconButton color="secondary" onClick={() => handleViewOpen(user)}>
                      <Eye variant="Bold" size={20}/>
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Edit">
                    <IconButton color="primary" onClick={() => handleOpen(user)}>
                      <Edit variant="Bold" size={20}/>
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Delete">
                    <IconButton color="error" onClick={() => handleDelete(user.user_id)}>
                      <Trash variant="Bold" size={20}/>
                    </IconButton>
                  </Tooltip>
                </TableCell>
              </TableRow>
            ))}
            {users.length === 0 && (
              <TableRow>
                <TableCell colSpan={7} align="center">
                  No users found
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Create/Edit Dialog */}
      <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
        <DialogTitle>{isEdit ? 'Edit User' : 'Create User'}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField
              name="username"
              label="Username"
              fullWidth
              value={formData.username}
              onChange={handleInputChange}
            />
            <TextField
              name="email_id"
              label="Email"
              fullWidth
              value={formData.email_id}
              onChange={handleInputChange}
            />
            <TextField
              name="phone_no"
              label="Phone Number"
              fullWidth
              value={formData.phone_no}
              onChange={handleInputChange}
            />
            <FormControl fullWidth>
              <InputLabel>Role</InputLabel>
              <Select
                name="role_id"
                value={formData.role_id}
                label="Role"
                onChange={handleInputChange}
              >
                {ROLES.map((role) => (
                  <MenuItem key={role.id} value={role.id}>
                    {role.name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            <TextField
              name="password"
              label={isEdit ? "New Password (leave blank to keep current)" : "Password"}
              type="password"
              fullWidth
              value={formData.password}
              onChange={handleInputChange}
            />
            <TextField
              name="rfid_tag"
              label="RFID Tag"
              fullWidth
              value={formData.rfid_tag}
              onChange={handleInputChange}
            />
            <TextField
                name="wallet_bal"
                label="Wallet Balance"
                type="number"
                fullWidth
                value={formData.wallet_bal}
                onChange={handleInputChange}
            />
            <FormControl component="fieldset">
                <Typography variant="body2" color="textSecondary">Status</Typography>
                <Stack direction="row" spacing={1} alignItems="center">
                    <Typography>Blocked</Typography>
                    <Switch 
                        checked={formData.status} 
                        onChange={(e) => setFormData(prev => ({ ...prev, status: e.target.checked }))} 
                    />
                    <Typography>Active</Typography>
                </Stack>
            </FormControl>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose} color="secondary">Cancel</Button>
          <Button onClick={handleSubmit} variant="contained">
            {isEdit ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* View Details Dialog */}
      <Dialog open={viewOpen} onClose={handleClose} maxWidth="sm" fullWidth>
        <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <User size={24} variant="Bold" />
            User Details
        </DialogTitle>
        <DialogContent dividers>
            {selectedUser && (
              <Grid container spacing={2}>
                <Grid item xs={12}>
                    <MainCard content={false} sx={{ p: 2 }}>
                        <Stack direction="row" spacing={2} alignItems="center">
                            <Box sx={{ width: 48, height: 48, borderRadius: '50%', bgcolor: 'primary.lighter', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <Typography variant="h4" color="primary.main">{selectedUser.username.charAt(0).toUpperCase()}</Typography>
                            </Box>
                            <Stack>
                                <Typography variant="h5">{selectedUser.username}</Typography>
                                <Typography variant="caption" color="textSecondary">User ID: {selectedUser.user_id}</Typography>
                            </Stack>
                            <Box sx={{ flexGrow: 1 }} />
                            <Chip 
                                label={selectedUser.status ? 'Active' : 'Blocked'} 
                                color={selectedUser.status ? 'success' : 'error'} 
                                size="small"
                                variant="combined"
                            />
                        </Stack>
                    </MainCard>
                </Grid>

                <Grid item xs={12}>
                    <Typography variant="h6" sx={{ mb: 2 }}>Contact Information</Typography>
                    <MainCard content={false}>
                        <Stack divider={<Divider />}>
                            <Stack direction="row" spacing={2} alignItems="center" sx={{ p: 2 }}>
                                <Sms size={20} color="#666" />
                                <Box>
                                    <Typography variant="caption" color="textSecondary">Email Address</Typography>
                                    <Typography variant="body1">{selectedUser.email_id}</Typography>
                                </Box>
                            </Stack>
                            <Stack direction="row" spacing={2} alignItems="center" sx={{ p: 2 }}>
                                <Call size={20} color="#666" />
                                <Box>
                                    <Typography variant="caption" color="textSecondary">Phone Number</Typography>
                                    <Typography variant="body1">{selectedUser.phone_no || 'N/A'}</Typography>
                                </Box>
                            </Stack>
                        </Stack>
                    </MainCard>
                </Grid>

                <Grid item xs={12}>
                    <Typography variant="h6" sx={{ mb: 2 }}>Account Details</Typography>
                    <Grid container spacing={2}>
                        <Grid item xs={6}>
                            <MainCard content={false} sx={{ p: 2 }}>
                                <Stack spacing={1}>
                                    <Stack direction="row" spacing={1} alignItems="center">
                                        <ShieldSecurity size={18} color="#666" />
                                        <Typography variant="caption" color="textSecondary">Role</Typography>
                                    </Stack>
                                    <Typography variant="subtitle1">{getRoleName(selectedUser.role_id)}</Typography>
                                </Stack>
                            </MainCard>
                        </Grid>
                        <Grid item xs={6}>
                            <MainCard content={false} sx={{ p: 2 }}>
                                <Stack spacing={1}>
                                    <Stack direction="row" spacing={1} alignItems="center">
                                        <Wallet size={18} color="#666" />
                                        <Typography variant="caption" color="textSecondary">Wallet Balance</Typography>
                                    </Stack>
                                    <Typography variant="subtitle1">₹{selectedUser.wallet_bal}</Typography>
                                </Stack>
                            </MainCard>
                        </Grid>
                        <Grid item xs={12}>
                             <MainCard content={false} sx={{ p: 2 }}>
                                <Stack spacing={1}>
                                    <Stack direction="row" spacing={1} alignItems="center">
                                        <ScanBarcode size={18} color="#666" />
                                        <Typography variant="caption" color="textSecondary">RFID Tag</Typography>
                                    </Stack>
                                    <Typography variant="subtitle1">{selectedUser.rfid_tag || 'N/A'}</Typography>
                                </Stack>
                            </MainCard>
                        </Grid>
                    </Grid>
                </Grid>
              </Grid>
            )}
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose} variant="contained">Close</Button>
        </DialogActions>
      </Dialog>
    </MainCard>
  );
}
