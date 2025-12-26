import PropTypes from 'prop-types';
import { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

// project-imports
import { useContext } from 'react';
import { AuthContext } from 'contexts/AuthContext';
import Loader from 'components/Loader';

// ==============================|| GUEST GUARD ||============================== //

export default function GuestGuard({ children }) {
  const { isAuthenticated, isInitialized } = useContext(AuthContext);
  const navigate = useNavigate();

  useEffect(() => {
    if (isInitialized && isAuthenticated) {
      navigate('/dashboard', { replace: true });
    }
  }, [isInitialized, isAuthenticated, navigate]);

  if (!isInitialized) return <Loader />;

  return children;
}

GuestGuard.propTypes = {
  children: PropTypes.node
};
