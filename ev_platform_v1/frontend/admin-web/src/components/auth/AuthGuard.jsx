import PropTypes from 'prop-types';
import { useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';

// project-imports
import { useContext } from 'react';
import { AuthContext } from 'contexts/AuthContext';
import Loader from 'components/Loader';

// ==============================|| AUTH GUARD ||============================== //

export default function AuthGuard({ children }) {
  const { isAuthenticated, isInitialized } = useContext(AuthContext);
  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    if (isInitialized && !isAuthenticated) {
      navigate('/login', {
        state: {
          from: location.pathname
        },
        replace: true
      });
    }
  }, [isInitialized, isAuthenticated, navigate, location]);

  if (!isInitialized) return <Loader />;
  if (!isAuthenticated) return <Loader />;

  return children;
}

AuthGuard.propTypes = {
  children: PropTypes.node
};
