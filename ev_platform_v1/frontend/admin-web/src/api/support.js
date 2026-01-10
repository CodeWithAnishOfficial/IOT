import axios from 'utils/axios';

const SupportService = {
  getAllTickets: (status) => {
    const params = status ? { status } : {};
    return axios.get('/admin/support', { params });
  },

  updateStatus: (ticketId, status) => {
    return axios.put(`/admin/support/${ticketId}/status`, { status });
  },

  addReply: (ticketId, message) => {
    return axios.post(`/admin/support/${ticketId}/reply`, { message });
  }
};

export default SupportService;
