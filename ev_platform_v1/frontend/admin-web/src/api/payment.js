import axios from 'utils/axios';

const PaymentService = {
  getPaymentHistory: async (page = 1, limit = 10) => {
    return axios.get(`/payments/history?page=${page}&limit=${limit}`);
  }
};

export default PaymentService;
