// assets
import { Money, Receipt } from 'iconsax-reactjs';

// icons
const icons = {
  tariffs: Money,
  history: Receipt
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
    },
    {
      id: 'payment-history',
      title: 'Payment History',
      type: 'item',
      url: '/payment-history',
      icon: icons.history
    }
  ]
};

export default billing;
