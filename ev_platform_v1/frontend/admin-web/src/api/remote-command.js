import axios from 'utils/axios';

const RemoteCommandService = {
  send: (chargerId, command, payload) => {
    return axios.post(`/commands/${chargerId}/send`, { command, payload });
  },

  startTransaction: (chargerId, idTag, connectorId) => {
    return axios.post(`/commands/${chargerId}/start-transaction`, { payload: { idTag, connectorId } });
  },

  stopTransaction: (chargerId, transactionId) => {
    return axios.post(`/commands/${chargerId}/stop-transaction`, { payload: { transactionId } });
  },

  unlockConnector: (chargerId, connectorId) => {
    return axios.post(`/commands/${chargerId}/unlock-connector`, { payload: { connectorId } });
  },

  reset: (chargerId, type = 'Soft') => {
    return axios.post(`/commands/${chargerId}/reset`, { type });
  }
};

export default RemoteCommandService;
