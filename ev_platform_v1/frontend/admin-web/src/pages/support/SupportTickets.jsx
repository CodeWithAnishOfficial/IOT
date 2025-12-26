import { useState, useEffect } from 'react';
import { useTheme } from '@mui/material/styles';

// material-ui
import {
  Grid,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Button,
  IconButton,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Stack,
  Alert,
  Typography,
  Chip,
  Box,
  Divider,
  List,
  ListItem,
  ListItemText,
  Avatar
} from '@mui/material';

// assets
import { Eye, Messages } from 'iconsax-reactjs';

// project-imports
import MainCard from 'components/MainCard';
import SupportService from 'api/support';

// Helper to format date
const formatDate = (dateString) => {
  return new Date(dateString).toLocaleString();
};

export default function SupportTickets() {
  const theme = useTheme();
  const [tickets, setTickets] = useState([]);
  const [loading, setLoading] = useState(true);
  const [open, setOpen] = useState(false);
  const [selectedTicket, setSelectedTicket] = useState(null);
  const [replyMessage, setReplyMessage] = useState('');
  const [filterStatus, setFilterStatus] = useState('');
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  useEffect(() => {
    fetchTickets();
  }, [filterStatus]);

  const fetchTickets = async () => {
    try {
      setLoading(true);
      const response = await SupportService.getAllTickets(filterStatus);
      if (!response.data.error) {
        setTickets(response.data.data);
      }
    } catch (error) {
      console.error('Error fetching tickets:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleOpen = (ticket) => {
    setSelectedTicket(ticket);
    setReplyMessage('');
    setOpen(true);
  };

  const handleClose = () => {
    setOpen(false);
    setSelectedTicket(null);
    setReplyMessage('');
  };

  const handleStatusChange = async (newStatus) => {
    if (!selectedTicket) return;
    try {
        await SupportService.updateStatus(selectedTicket.ticket_id, newStatus);
        setSuccess(`Status updated to ${newStatus}`);
        
        // Update local state
        setTickets(prev => prev.map(t => 
            t.ticket_id === selectedTicket.ticket_id ? { ...t, status: newStatus } : t
        ));
        
        setSelectedTicket(prev => ({ ...prev, status: newStatus }));

        setTimeout(() => setSuccess(null), 3000);
    } catch (error) {
        setError(error.response?.data?.message || 'Error updating status');
    }
  };

  const handleSendReply = async () => {
    if (!selectedTicket || !replyMessage.trim()) return;
    try {
        const response = await SupportService.addReply(selectedTicket.ticket_id, replyMessage);
        
        if (!response.data.error) {
            setSuccess('Reply sent successfully');
            
            // Update local state
            const updatedTicket = response.data.data;
            setTickets(prev => prev.map(t => 
                t.ticket_id === selectedTicket.ticket_id ? updatedTicket : t
            ));
            setSelectedTicket(updatedTicket);
            setReplyMessage('');
        }
    } catch (error) {
        setError(error.response?.data?.message || 'Error sending reply');
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'OPEN': return 'error';
      case 'IN_PROGRESS': return 'warning';
      case 'RESOLVED': return 'success';
      case 'CLOSED': return 'default';
      default: return 'primary';
    }
  };

  return (
    <MainCard secondary={
        <FormControl sx={{ minWidth: 120 }} size="small">
            <InputLabel>Filter Status</InputLabel>
            <Select
                value={filterStatus}
                label="Filter Status"
                onChange={(e) => setFilterStatus(e.target.value)}
            >
                <MenuItem value="">All</MenuItem>
                <MenuItem value="OPEN">Open</MenuItem>
                <MenuItem value="IN_PROGRESS">In Progress</MenuItem>
                <MenuItem value="RESOLVED">Resolved</MenuItem>
                <MenuItem value="CLOSED">Closed</MenuItem>
            </Select>
        </FormControl>
    }>
      {success && (
        <Alert severity="success" sx={{ mb: 2 }}>
          {success}
        </Alert>
      )}

      <TableContainer component={Paper} sx={{ boxShadow: 'none', border: '1px solid', borderColor: 'divider' }}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Ticket ID</TableCell>
              <TableCell>User ID</TableCell>
              <TableCell>Subject</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Priority</TableCell>
              <TableCell>Created At</TableCell>
              <TableCell align="right">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {tickets.map((ticket, index) => (
              <TableRow key={ticket.ticket_id} sx={{ backgroundColor: index % 2 !== 0 ? theme.palette.secondary.lighter : 'inherit' }}>
                <TableCell>{ticket.ticket_id}</TableCell>
                <TableCell>{ticket.user_id}</TableCell>
                <TableCell>{ticket.subject}</TableCell>
                <TableCell>
                  <Chip 
                    label={ticket.status} 
                    color={getStatusColor(ticket.status)} 
                    size="small" 
                  />
                </TableCell>
                <TableCell>
                    <Chip 
                        label={ticket.priority} 
                        color={ticket.priority === 'HIGH' ? 'error' : ticket.priority === 'MEDIUM' ? 'warning' : 'success'} 
                        variant="outlined"
                        size="small"
                    />
                </TableCell>
                <TableCell>{formatDate(ticket.created_at)}</TableCell>
                <TableCell align="right">
                  <Tooltip title="View & Reply">
                    <IconButton color="primary" onClick={() => handleOpen(ticket)}>
                      <Messages size="18" />
                    </IconButton>
                  </Tooltip>
                </TableCell>
              </TableRow>
            ))}
            {tickets.length === 0 && !loading && (
              <TableRow>
                <TableCell colSpan={7} align="center">
                  No tickets found
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* View/Reply Dialog */}
      <Dialog open={open} onClose={handleClose} maxWidth="md" fullWidth>
        {selectedTicket && (
            <>
                <DialogTitle>
                    <Stack direction="row" justifyContent="space-between" alignItems="center">
                        <Typography variant="h5">Ticket #{selectedTicket.ticket_id}</Typography>
                        <FormControl size="small" sx={{ width: 150 }}>
                            <Select
                                value={selectedTicket.status}
                                onChange={(e) => handleStatusChange(e.target.value)}
                            >
                                <MenuItem value="OPEN">Open</MenuItem>
                                <MenuItem value="IN_PROGRESS">In Progress</MenuItem>
                                <MenuItem value="RESOLVED">Resolved</MenuItem>
                                <MenuItem value="CLOSED">Closed</MenuItem>
                            </Select>
                        </FormControl>
                    </Stack>
                </DialogTitle>
                <Divider />
                <DialogContent>
                    <Stack spacing={3}>
                        <Box>
                            <Typography variant="subtitle2" color="textSecondary">Subject</Typography>
                            <Typography variant="h6">{selectedTicket.subject}</Typography>
                        </Box>
                        
                        <Box>
                             <Typography variant="subtitle2" color="textSecondary">Description</Typography>
                             <Typography variant="body1" sx={{ p: 2, bgcolor: 'secondary.lighter', borderRadius: 1 }}>
                                {selectedTicket.description}
                             </Typography>
                        </Box>

                        <Divider />
                        <Typography variant="h6">Conversation History</Typography>
                        
                        <List sx={{ maxHeight: 300, overflow: 'auto' }}>
                            {selectedTicket.responses && selectedTicket.responses.map((resp, index) => (
                                <ListItem key={index} alignItems="flex-start" sx={{ 
                                    flexDirection: 'column', 
                                    alignItems: resp.sender === 'admin' ? 'flex-end' : 'flex-start',
                                    mb: 2
                                }}>
                                    <Box sx={{ 
                                        bgcolor: resp.sender === 'admin' ? 'primary.lighter' : 'grey.100',
                                        p: 2,
                                        borderRadius: 2,
                                        maxWidth: '80%'
                                    }}>
                                        <Typography variant="caption" display="block" color="textSecondary" sx={{ mb: 0.5 }}>
                                            {resp.sender === 'admin' ? 'Support Team' : 'User'} • {formatDate(resp.timestamp)}
                                        </Typography>
                                        <Typography variant="body2">{resp.message}</Typography>
                                    </Box>
                                </ListItem>
                            ))}
                            {(!selectedTicket.responses || selectedTicket.responses.length === 0) && (
                                <Typography variant="body2" color="textSecondary" align="center">
                                    No responses yet.
                                </Typography>
                            )}
                        </List>

                        <Box sx={{ mt: 2 }}>
                            <TextField
                                fullWidth
                                multiline
                                rows={3}
                                placeholder="Type your reply here..."
                                value={replyMessage}
                                onChange={(e) => setReplyMessage(e.target.value)}
                            />
                            <Box sx={{ mt: 1, display: 'flex', justifyContent: 'flex-end' }}>
                                <Button variant="contained" onClick={handleSendReply} disabled={!replyMessage.trim()}>
                                    Send Reply
                                </Button>
                            </Box>
                        </Box>
                    </Stack>
                </DialogContent>
                <DialogActions>
                    <Button onClick={handleClose}>Close</Button>
                </DialogActions>
            </>
        )}
      </Dialog>
    </MainCard>
  );
}
