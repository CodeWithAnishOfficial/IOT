// assets
import { Money } from 'iconsax-reactjs';

// icons
const icons = {
  tariffs: Money
};

// ==============================|| MENU ITEMS - BILLING ||============================== //

const billing = {
  id: 'group-billing',
  title: 'Billing',
  type: 'group',
  children: [
    {
      id: 'tariffs',
      title: 'Tariffs',
      type: 'item',
      url: '/tariffs',
      icon: icons.tariffs
    }
  ]
};

export default billing;
