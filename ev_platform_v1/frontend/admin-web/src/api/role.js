import axios from 'utils/axios';

const RoleService = {
  getAllRoles: () => {
    return axios.get('/roles/list');
  },

  createRole: (roleData) => {
    return axios.post('/roles/create', roleData);
  },

  updateRole: (id, roleData) => {
    return axios.put(`/roles/${id}/update`, roleData);
  },

  deleteRole: (id) => {
    return axios.delete(`/roles/${id}/delete`);
  }
};

export default RoleService;
