import axios from 'utils/axios';

const SupportService = {
  getAllTickets: (status) => {
    const params = status ? { status } : {};
    return axios.get('/support', { params });
  },

  updateStatus: (ticketId, status) => {
    return axios.put(`/support/${ticketId}/status`, { status });
  },

  addReply: (ticketId, message) => {
    return axios.post(`/support/${ticketId}/reply`, { message });
  }
};

export default SupportService;
