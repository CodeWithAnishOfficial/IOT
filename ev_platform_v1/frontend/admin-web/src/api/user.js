import axios from 'utils/axios';

const UserService = {
  getAllUsers: (page = 1, limit = 10) => {
    return axios.get(`/users/list?page=${page}&limit=${limit}`);
  },

  getUserDetails: (id) => {
    return axios.get(`/users/details/${id}`);
  },

  createUser: (userData) => {
    return axios.post('/users/create', userData);
  },

  updateUser: (id, userData) => {
    return axios.put(`/users/update/${id}`, userData);
  },

  deleteUser: (id) => {
    return axios.delete(`/users/delete/${id}`);
  },

  toggleUserStatus: (id, status) => {
    return axios.put(`/users/status/${id}`, { status });
  }
};

export default UserService;
