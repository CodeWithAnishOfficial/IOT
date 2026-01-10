import axios from 'utils/axios';

const SessionService = {
  getAllSessions: (page = 1, limit = 10, filters = {}) => {
    const params = new URLSearchParams({
      page,
      limit,
      ...filters,
      _t: new Date().getTime() // Cache buster
    });
    return axios.get(`/sessions?${params.toString()}`);
  },

  getSessionDetails: (id) => {
    return axios.get(`/sessions/${id}?_t=${new Date().getTime()}`);
  }
};

export default SessionService;
