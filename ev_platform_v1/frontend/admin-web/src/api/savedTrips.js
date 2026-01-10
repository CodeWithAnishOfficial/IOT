import axios from 'utils/axios';

const SavedTripService = {
  getAllSavedTrips: (page = 1, limit = 10, filters = {}) => {
    const params = new URLSearchParams({
      page,
      limit,
      ...filters,
      _t: new Date().getTime() // Cache buster
    });
    return axios.get(`/admin-saved-trips?${params.toString()}`);
  },

  getSavedTripDetails: (id) => {
    return axios.get(`/admin-saved-trips/${id}?_t=${new Date().getTime()}`);
  }
};

export default SavedTripService;
