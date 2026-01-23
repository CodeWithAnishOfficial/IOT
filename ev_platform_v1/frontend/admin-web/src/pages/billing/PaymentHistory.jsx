import { useState, useEffect } from 'react';
import { useTheme } from '@mui/material/styles';

// material-ui
import {
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Stack,
  Typography,
  Chip,
  Box,
  IconButton,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Grid
} from '@mui/material';

// assets
import { Receipt, Eye, Card, Wallet, Mobile } from 'iconsax-reactjs';

// project-imports
import MainCard from 'components/MainCard';
import PaymentService from 'api/payment';

// helper function for status color
const getStatusColor = (status) => {
  if (status === true || status === 'SUCCESS') return 'success';
  if (status === false || status === 'FAILED') return 'error';
  return 'warning';
};

const getStatusLabel = (status) => {
    if (status === true || status === 'SUCCESS') return 'COMPLETED';
    if (status === false || status === 'FAILED') return 'FAILED';
    return 'PENDING';
}

const getMethodIcon = (method) => {
  if (!method) return <Receipt size="18" />;
  if (method.toLowerCase().includes('card')) return <Card size="18" />;
  if (method.toLowerCase().includes('wallet')) return <Wallet size="18" />;
  if (method.toLowerCase().includes('upi') || method.toLowerCase().includes('mobile')) return <Mobile size="18" />;
  return <Receipt size="18" />;
};

export default function PaymentHistory() {
  const theme = useTheme();
  const [payments, setPayments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [viewOpen, setViewOpen] = useState(false);
  const [selectedPayment, setSelectedPayment] = useState(null);
  
  // Pagination state
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);
  const LIMIT = 10;

  useEffect(() => {
    fetchPaymentHistory(1, true); // Initial load
  }, []);

  const fetchPaymentHistory = async (pageNum = 1, isRefresh = false) => {
    try {
      if (isRefresh) {
        setLoading(true);
      }
      
      const response = await PaymentService.getPaymentHistory(pageNum, LIMIT);
      
      if (!response.data.error) {
        const newPayments = response.data.data;
        const pagination = response.data.pagination;
        
        setPayments(prev => isRefresh ? newPayments : [...prev, ...newPayments]);
        
        if (pagination) {
            setHasMore(pagination.page < pagination.pages);
        } else {
            setHasMore(newPayments.length === LIMIT);
        }
      }
    } catch (error) {
      console.error('Error fetching payment history:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleLoadMore = () => {
    const nextPage = page + 1;
    setPage(nextPage);
    fetchPaymentHistory(nextPage, false);
  };

  const handleViewOpen = (payment) => {
    setSelectedPayment(payment);
    setViewOpen(true);
  };

  const handleClose = () => {
    setViewOpen(false);
  };

  return (
    <MainCard title="Payment History">
      <TableContainer component={Paper} sx={{ boxShadow: 'none', border: '1px solid', borderColor: 'divider' }}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Transaction ID</TableCell>
              <TableCell>User</TableCell>
              <TableCell>Amount</TableCell>
              <TableCell>Method</TableCell>
              <TableCell>Date</TableCell>
              <TableCell>Status</TableCell>
              <TableCell align="right">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {payments.map((payment, index) => (
              <TableRow key={payment._id || payment.payment_id} sx={{ backgroundColor: index % 2 !== 0 ? theme.palette.secondary.lighter : 'inherit' }}>
                <TableCell>
                    <Typography variant="subtitle1">{payment.payment_id}</Typography>
                    <Typography variant="caption" color="textSecondary">{payment.transaction_id}</Typography>
                </TableCell>
                <TableCell>
                  <Typography variant="subtitle1">{payment.username || 'Unknown'}</Typography>
                  <Typography variant="caption" color="textSecondary">{payment.email_id}</Typography>
                </TableCell>
                <TableCell>{payment.currency || 'INR'} {(payment.recharge_amount || 0).toFixed(2)}</TableCell>
                <TableCell>
                    <Stack direction="row" spacing={1} alignItems="center">
                        {getMethodIcon(payment.payment_method)}
                        <Typography>{payment.payment_method || 'N/A'}</Typography>
                    </Stack>
                </TableCell>
                <TableCell>{payment.recharged_date ? new Date(payment.recharged_date).toLocaleString() : 'N/A'}</TableCell>
                <TableCell>
                  <Chip 
                    label={getStatusLabel(payment.status)} 
                    color={getStatusColor(payment.status)} 
                    size="small" 
                  />
                </TableCell>
                <TableCell align="right">
                  <Stack direction="row" spacing={1} justifyContent="flex-end">
                    <Tooltip title="View Details">
                      <IconButton color="secondary" onClick={() => handleViewOpen(payment)}>
                        <Eye size="18" variant="Bold" />
                      </IconButton>
                    </Tooltip>
                  </Stack>
                </TableCell>
              </TableRow>
            ))}
            {payments.length === 0 && !loading && (
              <TableRow>
                <TableCell colSpan={7} align="center">
                  No payment records found
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>
      
      {hasMore && !loading && (
        <Box sx={{ p: 2, display: 'flex', justifyContent: 'center' }}>
            <Button onClick={handleLoadMore} variant="outlined">
                Load More
            </Button>
        </Box>
      )}

      {/* View Details Dialog */}
      <Dialog open={viewOpen} onClose={handleClose} maxWidth="sm" fullWidth>
        <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Receipt size={24} variant="Bold" />
            Transaction Details
        </DialogTitle>
        <DialogContent dividers>
            {selectedPayment && (
              <Grid container spacing={2}>
                 <Grid size={{ xs: 12 }}>
                    <MainCard content={false} sx={{ p: 2 }}>
                        <Stack direction="row" spacing={2} alignItems="center" sx={{ mb: 2 }}>
                            <Box sx={{ width: 48, height: 48, borderRadius: '12px', bgcolor: 'primary.lighter', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <Receipt size={24} color="#333" variant="Bold" />
                            </Box>
                            <Stack>
                                <Typography variant="h5">{selectedPayment.currency || 'INR'} {(selectedPayment.recharge_amount || 0).toFixed(2)}</Typography>
                                <Typography color="textSecondary">{selectedPayment.payment_id}</Typography>
                            </Stack>
                            <Box sx={{ flexGrow: 1 }} />
                            <Chip 
                                label={getStatusLabel(selectedPayment.status)} 
                                color={getStatusColor(selectedPayment.status)} 
                            />
                        </Stack>
                        
                        <Stack spacing={2}>
                            <Stack direction="row" justifyContent="space-between">
                                <Typography color="textSecondary">User Name</Typography>
                                <Typography variant="subtitle1">{selectedPayment.username || 'Unknown'}</Typography>
                            </Stack>
                            <Stack direction="row" justifyContent="space-between">
                                <Typography color="textSecondary">Email</Typography>
                                <Typography variant="subtitle1">{selectedPayment.email_id}</Typography>
                            </Stack>
                            <Stack direction="row" justifyContent="space-between">
                                <Typography color="textSecondary">Payment Method</Typography>
                                <Typography variant="subtitle1">{selectedPayment.payment_method || 'N/A'}</Typography>
                            </Stack>
                            <Stack direction="row" justifyContent="space-between">
                                <Typography color="textSecondary">Transaction ID</Typography>
                                <Typography variant="subtitle1">{selectedPayment.transaction_id}</Typography>
                            </Stack>
                            <Stack direction="row" justifyContent="space-between">
                                <Typography color="textSecondary">Date & Time</Typography>
                                <Typography variant="subtitle1">{selectedPayment.recharged_date ? new Date(selectedPayment.recharged_date).toLocaleString() : 'N/A'}</Typography>
                            </Stack>
                             <Stack direction="row" justifyContent="space-between">
                                <Typography color="textSecondary">Recharged By</Typography>
                                <Typography variant="subtitle1">{selectedPayment.recharged_by || 'N/A'}</Typography>
                            </Stack>
                             <Stack direction="row" justifyContent="space-between">
                                <Typography color="textSecondary">Response</Typography>
                                <Typography variant="subtitle1">{selectedPayment.response || 'N/A'}</Typography>
                            </Stack>
                        </Stack>
                    </MainCard>
                 </Grid>
              </Grid>
            )}
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose} variant="contained">
            Close
          </Button>
        </DialogActions>
      </Dialog>
    </MainCard>
  );
}
