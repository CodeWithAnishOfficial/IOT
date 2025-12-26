import axios from 'axios';

const axiosServices = axios.create({
  baseURL: import.meta.env.VITE_APP_API_URL || 'http://localhost:3000'
});

// interceptor for http
axiosServices.interceptors.response.use(
  (response) => response,
  (error) => Promise.reject((error.response && error.response.data) || 'Wrong Services')
);

export default axiosServices;
