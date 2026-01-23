import axios from 'utils/axios';

const AnalyticsService = {
  getUserAnalytics: async () => {
    return axios.get('/analytics/users');
  },
  getChargerAnalytics: async () => {
    return axios.get('/analytics/chargers');
  },
  getUserDetailAnalytics: async (id) => {
    return axios.get(`/analytics/users/${id}`);
  }
};

export default AnalyticsService;
