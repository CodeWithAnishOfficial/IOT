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
  CircularProgress,
  Box,
  IconButton,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Tooltip,
  Stack
} from '@mui/material';

// icons
import { Edit, Trash, Add } from 'iconsax-reactjs';

// project-imports
import MainCard from 'components/MainCard';
import RoleService from 'api/role';

export default function RolesList() {
  const theme = useTheme();
  const [roles, setRoles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [open, setOpen] = useState(false);
  const [isEdit, setIsEdit] = useState(false);
  const [selectedRole, setSelectedRole] = useState(null);

  // Form State
  const [formData, setFormData] = useState({
    role_name: '',
    description: ''
  });

  useEffect(() => {
    fetchRoles();
  }, []);

  const fetchRoles = async () => {
    try {
      const response = await RoleService.getAllRoles();
      if (!response.data.error) {
        setRoles(response.data.data);
      }
    } catch (error) {
      console.error('Error fetching roles:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleOpen = (role = null) => {
    if (role) {
      setIsEdit(true);
      setSelectedRole(role);
      setFormData({
        role_name: role.role_name,
        description: role.description || ''
      });
    } else {
      setIsEdit(false);
      setSelectedRole(null);
      setFormData({
        role_name: '',
        description: ''
      });
    }
    setOpen(true);
  };

  const handleClose = () => {
    setOpen(false);
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async () => {
    try {
      if (isEdit) {
        await RoleService.updateRole(selectedRole.role_id, formData);
      } else {
        await RoleService.createRole(formData);
      }
      fetchRoles();
      handleClose();
    } catch (error) {
      console.error('Error saving role:', error);
      alert(error.response?.data?.message || 'Error saving role');
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this role?')) {
      try {
        await RoleService.deleteRole(id);
        fetchRoles();
      } catch (error) {
        console.error('Error deleting role:', error);
        alert(error.response?.data?.message || 'Error deleting role');
      }
    }
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <MainCard title="Roles" secondary={
      <Button variant="contained" startIcon={<Add />} onClick={() => handleOpen()}>
        Add Role
      </Button>
    }>
      <TableContainer component={Paper} sx={{ boxShadow: 'none', border: '1px solid', borderColor: 'divider' }}>
        <Table sx={{ minWidth: 650 }} aria-label="roles table">
          <TableHead>
            <TableRow>
              <TableCell>Role ID</TableCell>
              <TableCell>Role Name</TableCell>
              <TableCell>Description</TableCell>
              <TableCell align="right">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {roles.map((role, index) => (
              <TableRow key={role.role_id} sx={{ backgroundColor: index % 2 !== 0 ? theme.palette.secondary.lighter : 'inherit' }}>
                <TableCell>{role.role_id}</TableCell>
                <TableCell>{role.role_name}</TableCell>
                <TableCell>{role.description}</TableCell>
                <TableCell align="right">
                  <Tooltip title="Edit">
                    <IconButton color="primary" onClick={() => handleOpen(role)}>
                      <Edit variant="Bold" size={20}/>
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Delete">
                    <IconButton color="error" onClick={() => handleDelete(role.role_id)}>
                      <Trash variant="Bold" size={20}/>
                    </IconButton>
                  </Tooltip>
                </TableCell>
              </TableRow>
            ))}
            {roles.length === 0 && (
              <TableRow>
                <TableCell colSpan={4} align="center">
                  No roles found
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Create/Edit Dialog */}
      <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
        <DialogTitle>{isEdit ? 'Edit Role' : 'Create Role'}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField
              name="role_name"
              label="Role Name"
              fullWidth
              value={formData.role_name}
              onChange={handleInputChange}
              required
            />
            <TextField
              name="description"
              label="Description"
              fullWidth
              multiline
              rows={3}
              value={formData.description}
              onChange={handleInputChange}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose} color="secondary">Cancel</Button>
          <Button onClick={handleSubmit} variant="contained">
            {isEdit ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>
    </MainCard>
  );
}
