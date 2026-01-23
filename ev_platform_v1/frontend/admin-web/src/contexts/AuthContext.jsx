import { createContext, useEffect, useReducer } from 'react';
import { jwtDecode } from 'jwt-decode';
import axios from 'utils/axios';

// ----------------------------------------------------------------------

const initialState = {
  isInitialized: false,
  isAuthenticated: false,
  user: null
};

const AuthContext = createContext({
  ...initialState,
  login: () => Promise.resolve(),
  logout: () => Promise.resolve()
});

// ----------------------------------------------------------------------

const handlers = {
  INITIALIZE: (state, action) => {
    const { isAuthenticated, user } = action.payload;
    return {
      ...state,
      isInitialized: true,
      isAuthenticated,
      user
    };
  },
  LOGIN: (state, action) => {
    const { user } = action.payload;
    return {
      ...state,
      isAuthenticated: true,
      user
    };
  },
  LOGOUT: (state) => ({
    ...state,
    isAuthenticated: false,
    user: null
  })
};

const reducer = (state, action) => (handlers[action.type] ? handlers[action.type](state, action) : state);

// ----------------------------------------------------------------------

function AuthProvider({ children }) {
  const [state, dispatch] = useReducer(reducer, initialState);

  useEffect(() => {
    const initialize = async () => {
      try {
        const accessToken = localStorage.getItem('accessToken');

        if (accessToken) {
          const decoded = jwtDecode(accessToken);
          // Check if token is expired
          if (decoded.exp * 1000 < Date.now()) {
            throw new Error('Token expired');
          }
          
          axios.defaults.headers.common.Authorization = `Bearer ${accessToken}`;

          dispatch({
            type: 'INITIALIZE',
            payload: {
              isAuthenticated: true,
              user: decoded // or fetch full user details if needed
            }
          });
        } else {
          dispatch({
            type: 'INITIALIZE',
            payload: {
              isAuthenticated: false,
              user: null
            }
          });
        }
      } catch (err) {
        console.error(err);
        localStorage.removeItem('accessToken');
        delete axios.defaults.headers.common.Authorization;
        dispatch({
          type: 'INITIALIZE',
          payload: {
            isAuthenticated: false,
            user: null
          }
        });
      }
    };

    initialize();
  }, []);

  const login = async (email, password) => {
    const response = await axios.post('/auth/login', {
      email,
      password
    });
    const { token, user } = response.data;

    localStorage.setItem('accessToken', token);
    axios.defaults.headers.common.Authorization = `Bearer ${token}`;

    dispatch({
      type: 'LOGIN',
      payload: {
        user
      }
    });
  };

  const logout = () => {
    localStorage.removeItem('accessToken');
    delete axios.defaults.headers.common.Authorization;
    dispatch({ type: 'LOGOUT' });
  };

  return (
    <AuthContext.Provider
      value={{
        ...state,
        login,
        logout
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export { AuthContext, AuthProvider };
