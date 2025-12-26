import axios from 'utils/axios';

const ProfileService = {
  getProfile: (id) => {
    return axios.get(`/users/details/${id}`);
  },

  updateProfile: (id, data) => {
    return axios.put(`/users/update/${id}`, data);
  }
};

export default ProfileService;
