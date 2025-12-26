import axios from 'utils/axios';

const TariffService = {
  getAllTariffs: () => {
    return axios.get('/tariffs/list');
  },

  createTariff: (tariffData) => {
    return axios.post('/tariffs/create', tariffData);
  },

  updateTariff: (id, tariffData) => {
    return axios.put(`/tariffs/update/${id}`, tariffData);
  },

  deleteTariff: (id) => {
    return axios.delete(`/tariffs/delete/${id}`);
  }
};

export default TariffService;
