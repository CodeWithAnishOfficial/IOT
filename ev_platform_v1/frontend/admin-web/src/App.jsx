import { RouterProvider } from 'react-router-dom';

// project-imports
import router from 'routes';
import ThemeCustomization from 'themes';
import ScrollTop from 'components/ScrollTop';
import { AuthProvider } from 'contexts/AuthContext';

// ==============================|| APP - THEME, ROUTER, LOCAL  ||============================== //

export default function App() {
  return (
    <ThemeCustomization>
      <ScrollTop>
        <AuthProvider>
          <RouterProvider router={router} />
        </AuthProvider>
      </ScrollTop>
    </ThemeCustomization>
  );
}
