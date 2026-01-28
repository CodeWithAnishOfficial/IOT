// assets
import { Buildings, Flash } from 'iconsax-reactjs';

// icons
const icons = {
  sites: Buildings,
  stations: Flash
};

// ==============================|| MENU ITEMS - INFRASTRUCTURE ||============================== //

const infrastructure = {
  id: 'group-infrastructure',
  title: 'Infrastructure',
  type: 'group',
  children: [
    {
      id: 'sites',
      title: 'Sites',
      type: 'item',
      url: '/sites',
      icon: icons.sites
    },
    {
      id: 'chargers',
      title: 'Chargers',
      type: 'item',
      url: '/chargers',
      icon: icons.stations
    },
    {
      id: 'commercial-chargers',
      title: 'Commercial Chargers',
      type: 'item',
      url: '/commercial-chargers',
      icon: icons.stations
    }
  ]
};

export default infrastructure;
