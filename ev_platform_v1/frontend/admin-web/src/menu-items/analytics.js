// assets
import { Chart, Profile2User, Flash } from 'iconsax-reactjs';

// icons
const icons = {
  analytics: Chart,
  users: Profile2User,
  chargers: Flash
};

// ==============================|| MENU ITEMS - ANALYTICS ||============================== //

const analytics = {
  id: 'group-analytics',
  title: 'Analytics',
  type: 'group',
  children: [
    {
      id: 'user-analytics',
      title: 'User Analytics',
      type: 'item',
      url: '/analytics/users',
      icon: icons.users
    },
    {
      id: 'charger-analytics',
      title: 'Charger Analytics',
      type: 'item',
      url: '/analytics/chargers',
      icon: icons.chargers
    }
  ]
};

export default analytics;
