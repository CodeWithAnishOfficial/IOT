import axios from 'utils/axios';

const ChargerService = {
  getAllChargers: (params) => {
    return axios.get('/chargers/list', { params });
  },

  getChargerDetails: (id) => {
    return axios.get(`/chargers/details/${id}`);
  },

  createCharger: (chargerData) => {
    return axios.post('/chargers/create', chargerData);
  },

  updateCharger: (id, chargerData) => {
    return axios.put(`/chargers/update/${id}`, chargerData);
  },

  deleteCharger: (id) => {
    return axios.delete(`/chargers/delete/${id}`);
  }
};

export default ChargerService;
