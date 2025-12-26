import { useState, useEffect } from 'react';

// material-ui
import {
  Grid,
  TextField,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Stack,
  Alert,
  Typography,
  Card,
  CardContent,
  Divider,
  CircularProgress,
  Box
} from '@mui/material';

// project-imports
import MainCard from 'components/MainCard';
import StationService from 'api/station';
import RemoteCommandService from 'api/remote-command';

export default function RemoteCommands() {
  const [stations, setStations] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedStation, setSelectedStation] = useState('');
  const [commandType, setCommandType] = useState('RemoteStartTransaction');
  const [commandStatus, setCommandStatus] = useState(null); // { type: 'success' | 'error', message: '' }
  const [sending, setSending] = useState(false);

  // Command Parameters
  const [params, setParams] = useState({
    connectorId: 1,
    idTag: '',
    transactionId: '',
    resetType: 'Soft',
    customCommand: '',
    customPayload: '{}'
  });

  useEffect(() => {
    fetchStations();
  }, []);

  const fetchStations = async () => {
    try {
      const response = await StationService.getAllStations();
      if (!response.data.error) {
        setStations(response.data.data);
      }
    } catch (error) {
      console.error('Error fetching stations:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleParamChange = (e) => {
    const { name, value } = e.target;
    setParams(prev => ({ ...prev, [name]: value }));
  };

  const handleCommandChange = (e) => {
    setCommandType(e.target.value);
    setCommandStatus(null);
  };

  const handleStationChange = (e) => {
    setSelectedStation(e.target.value);
    setCommandStatus(null);
  };

  const executeCommand = async () => {
    if (!selectedStation) {
      setCommandStatus({ type: 'error', message: 'Please select a charging station' });
      return;
    }

    setSending(true);
    setCommandStatus(null);

    try {
      let response;
      switch (commandType) {
        case 'RemoteStartTransaction':
          if (!params.idTag) throw new Error('ID Tag is required');
          response = await RemoteCommandService.startTransaction(selectedStation, params.idTag, parseInt(params.connectorId));
          break;
        case 'RemoteStopTransaction':
          if (!params.transactionId) throw new Error('Transaction ID is required');
          response = await RemoteCommandService.stopTransaction(selectedStation, parseInt(params.transactionId));
          break;
        case 'UnlockConnector':
          response = await RemoteCommandService.unlockConnector(selectedStation, parseInt(params.connectorId));
          break;
        case 'Reset':
          response = await RemoteCommandService.reset(selectedStation, params.resetType);
          break;
        case 'Custom':
            if (!params.customCommand) throw new Error('Command Name is required');
            let payload = {};
            try {
                payload = JSON.parse(params.customPayload);
            } catch (e) {
                throw new Error('Invalid JSON Payload');
            }
            response = await RemoteCommandService.send(selectedStation, params.customCommand, payload);
            break;
        default:
          throw new Error('Unknown command type');
      }

      if (!response.data.error) {
        setCommandStatus({ type: 'success', message: response.data.message || 'Command sent successfully' });
      } else {
        setCommandStatus({ type: 'error', message: response.data.message || 'Failed to send command' });
      }
    } catch (error) {
      console.error('Command Error:', error);
      setCommandStatus({ type: 'error', message: error.message || error.response?.data?.message || 'Error sending command' });
    } finally {
      setSending(false);
    }
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <MainCard title="Remote Commands">
      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Stack spacing={3}>
            <FormControl fullWidth>
              <InputLabel>Charging Station</InputLabel>
              <Select
                value={selectedStation}
                label="Charging Station"
                onChange={handleStationChange}
              >
                {stations.map((station) => (
                  <MenuItem key={station.charger_id} value={station.charger_id}>
                    {station.name} ({station.charger_id}) - {station.status}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            <FormControl fullWidth>
              <InputLabel>Command</InputLabel>
              <Select
                value={commandType}
                label="Command"
                onChange={handleCommandChange}
              >
                <MenuItem value="RemoteStartTransaction">Remote Start Transaction</MenuItem>
                <MenuItem value="RemoteStopTransaction">Remote Stop Transaction</MenuItem>
                <MenuItem value="UnlockConnector">Unlock Connector</MenuItem>
                <MenuItem value="Reset">Reset</MenuItem>
                <MenuItem value="Custom">Custom Command</MenuItem>
              </Select>
            </FormControl>

            <Divider />

            {/* Command Parameters Form */}
            <Card variant="outlined">
              <CardContent>
                <Typography variant="subtitle1" gutterBottom>Parameters</Typography>
                <Stack spacing={2}>
                  {commandType === 'RemoteStartTransaction' && (
                    <>
                      <TextField
                        name="idTag"
                        label="ID Tag (RFID)"
                        fullWidth
                        value={params.idTag}
                        onChange={handleParamChange}
                        placeholder="e.g. MY_TAG_123"
                      />
                      <TextField
                        name="connectorId"
                        label="Connector ID"
                        type="number"
                        fullWidth
                        value={params.connectorId}
                        onChange={handleParamChange}
                      />
                    </>
                  )}

                  {commandType === 'RemoteStopTransaction' && (
                    <TextField
                      name="transactionId"
                      label="Transaction ID"
                      type="number"
                      fullWidth
                      value={params.transactionId}
                      onChange={handleParamChange}
                    />
                  )}

                  {commandType === 'UnlockConnector' && (
                    <TextField
                      name="connectorId"
                      label="Connector ID"
                      type="number"
                      fullWidth
                      value={params.connectorId}
                      onChange={handleParamChange}
                    />
                  )}

                  {commandType === 'Reset' && (
                    <FormControl fullWidth>
                      <InputLabel>Type</InputLabel>
                      <Select
                        name="resetType"
                        value={params.resetType}
                        label="Type"
                        onChange={handleParamChange}
                      >
                        <MenuItem value="Soft">Soft</MenuItem>
                        <MenuItem value="Hard">Hard</MenuItem>
                      </Select>
                    </FormControl>
                  )}

                  {commandType === 'Custom' && (
                      <>
                        <TextField
                            name="customCommand"
                            label="Command Name"
                            fullWidth
                            value={params.customCommand}
                            onChange={handleParamChange}
                            placeholder="e.g. GetConfiguration"
                        />
                         <TextField
                            name="customPayload"
                            label="Payload (JSON)"
                            fullWidth
                            multiline
                            rows={4}
                            value={params.customPayload}
                            onChange={handleParamChange}
                            placeholder='{"key": "value"}'
                        />
                      </>
                  )}
                </Stack>
              </CardContent>
            </Card>

            <Button
              variant="contained"
              size="large"
              onClick={executeCommand}
              disabled={sending || !selectedStation}
            >
              {sending ? 'Sending...' : 'Send Command'}
            </Button>

            {commandStatus && (
              <Alert severity={commandStatus.type} onClose={() => setCommandStatus(null)}>
                {commandStatus.message}
              </Alert>
            )}
          </Stack>
        </Grid>
        
        <Grid item xs={12} md={6}>
            <MainCard title="Help & Information">
                <Typography variant="body2" paragraph>
                    Use this interface to send OCPP commands directly to connected charging stations.
                </Typography>
                <Typography variant="body2" paragraph>
                    <strong>Remote Start:</strong> Initiates a charging session. Requires a valid ID Tag (RFID).
                </Typography>
                <Typography variant="body2" paragraph>
                    <strong>Remote Stop:</strong> Stops an active transaction. Requires the Transaction ID.
                </Typography>
                <Typography variant="body2" paragraph>
                    <strong>Unlock Connector:</strong> Unlocks the cable if stuck.
                </Typography>
                <Typography variant="body2" paragraph>
                    <strong>Reset:</strong> Soft reset reboots the software. Hard reset reboots the hardware.
                </Typography>
            </MainCard>
        </Grid>
      </Grid>
    </MainCard>
  );
}
