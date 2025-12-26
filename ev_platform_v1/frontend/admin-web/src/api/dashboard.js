import axios from 'utils/axios';

const DashboardService = {
  getStats: () => {
    return axios.get('/dashboard/stats');
  },
  getAnalytics: () => {
    return axios.get('/dashboard/analytics');
  },
  getRecentActivity: () => {
    return axios.get('/dashboard/recent-activity');
  }
};

export default DashboardService;
