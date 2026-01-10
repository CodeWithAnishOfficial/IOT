import { lazy } from 'react';

// project-imports
import Loadable from 'components/Loadable';
import DashboardLayout from 'layout/Dashboard';

// render - Dashboard
const DashboardDefault = Loadable(lazy(() => import('pages/dashboard/default')));

// render - Pages
const UsersList = Loadable(lazy(() => import('pages/users/UsersList')));
const SavedTripsList = Loadable(lazy(() => import('pages/users/SavedTripsList')));
const RolesList = Loadable(lazy(() => import('pages/users/RolesList')));
const SitesList = Loadable(lazy(() => import('pages/infrastructure/SitesList')));
const ChargersList = Loadable(lazy(() => import('pages/infrastructure/ChargersList')));
const SessionsList = Loadable(lazy(() => import('pages/operations/SessionsList')));
const RemoteCommands = Loadable(lazy(() => import('pages/operations/RemoteCommands')));
const SystemMonitor = Loadable(lazy(() => import('pages/operations/SystemMonitor')));
const TariffsList = Loadable(lazy(() => import('pages/billing/TariffsList')));
const SupportTickets = Loadable(lazy(() => import('pages/support/SupportTickets')));
const UserProfile = Loadable(lazy(() => import('pages/users/Profile')));

// render - utils components
const Color = Loadable(lazy(() => import('pages/component-overview/color')));
const Typography = Loadable(lazy(() => import('pages/component-overview/typography')));
const Shadow = Loadable(lazy(() => import('pages/component-overview/shadows')));

// render - sample page
const SamplePage = Loadable(lazy(() => import('pages/extra-pages/sample-page')));
const Error404 = Loadable(lazy(() => import('pages/error/Error404')));

import AuthGuard from 'components/auth/AuthGuard';

// ==============================|| MAIN ROUTES ||============================== //

const MainRoutes = {
  path: '/',
  element: (
    <AuthGuard>
      <DashboardLayout />
    </AuthGuard>
  ),
  errorElement: <Error404 />,
  children: [
    {
      path: '/',
      element: <DashboardDefault />
    },
    {
      path: '/',
      children: [
        {
          path: 'dashboard',
          element: <DashboardDefault />
        }
      ]
    },
    {
      path: 'users',
      element: <UsersList />
    },
    {
      path: 'saved-trips',
      element: <SavedTripsList />
    },
    {
      path: 'users/sessions',
      element: <SessionsList />
    },
    {
      path: 'roles',
      element: <RolesList />
    },
    {
      path: 'sites',
      element: <SitesList />
    },
    {
      path: 'chargers',
      element: <ChargersList />
    },
    {
      path: 'chargers/sessions',
      element: <SessionsList />
    },
    {
      path: 'sessions',
      element: <SessionsList />
    },
    {
      path: 'remote-commands',
      element: <RemoteCommands />
    },
    {
      path: 'system-monitor',
      element: <SystemMonitor />
    },
    {
      path: 'tariffs',
      element: <TariffsList />
    },
    {
      path: 'support',
      element: <SupportTickets />
    },
    {
      path: 'profile',
      element: <UserProfile />
    },
    {
      path: 'typography',
      element: <Typography />
    },
    {
      path: 'color',
      element: <Color />
    },
    {
      path: 'shadows',
      element: <Shadow />
    },
    {
      path: 'sample-page',
      element: <SamplePage />
    },
    {
      path: '*',
      element: <Error404 />
    }
  ]
};

export default MainRoutes;
