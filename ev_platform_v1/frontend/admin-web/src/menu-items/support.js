// assets
import { I24Support } from 'iconsax-reactjs';

// icons
const icons = {
  support: I24Support
};

// ==============================|| MENU ITEMS - SUPPORT ||============================== //

const support = {
  id: 'group-support',
  title: 'Support',
  type: 'group',
  children: [
    {
      id: 'support-tickets',
      title: 'Support Tickets',
      type: 'item',
      url: '/support',
      icon: icons.support
    }
  ]
};

export default support;
