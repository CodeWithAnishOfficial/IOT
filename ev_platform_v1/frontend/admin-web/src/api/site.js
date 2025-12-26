import axios from 'utils/axios';

const SiteService = {
  getAllSites: () => {
    return axios.get('/sites/list');
  },

  getSiteDetails: (id) => {
    return axios.get(`/sites/details/${id}`);
  },

  createSite: (siteData) => {
    return axios.post('/sites/create', siteData);
  },

  updateSite: (id, siteData) => {
    return axios.put(`/sites/update/${id}`, siteData);
  },

  deleteSite: (id) => {
    return axios.delete(`/sites/delete/${id}`);
  },

  uploadImage: (formData) => {
    return axios.post('/sites/upload', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
  }
};

export default SiteService;
