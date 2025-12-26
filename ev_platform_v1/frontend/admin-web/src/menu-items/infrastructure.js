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
      id: 'stations',
      title: 'Charging Stations',
      type: 'item',
      url: '/charging-stations',
      icon: icons.stations
    }
  ]
};

export default infrastructure;
