import axios from 'utils/axios';

const StationService = {
  getAllStations: () => {
    return axios.get('/stations/list');
  },

  getStationDetails: (id) => {
    return axios.get(`/stations/details/${id}`);
  },

  createStation: (stationData) => {
    return axios.post('/stations/create', stationData);
  },

  updateStation: (id, stationData) => {
    return axios.put(`/stations/update/${id}`, stationData);
  },

  deleteStation: (id) => {
    return axios.delete(`/stations/delete/${id}`);
  }
};

export default StationService;
