// assets
import { Activity, Command, Monitor } from 'iconsax-reactjs';

// icons
const icons = {
  sessions: Activity,
  commands: Command,
  monitor: Monitor
};

// ==============================|| MENU ITEMS - OPERATIONS ||============================== //

const operations = {
  id: 'group-operations',
  title: 'Operations',
  type: 'group',
  children: [
    {
      id: 'sessions',
      title: 'Sessions',
      type: 'item',
      url: '/sessions',
      icon: icons.sessions
    },
    {
      id: 'remote-commands',
      title: 'Remote Commands',
      type: 'item',
      url: '/remote-commands',
      icon: icons.commands
    },
    {
      id: 'system-monitor',
      title: 'System Monitor',
      type: 'item',
      url: '/system-monitor',
      icon: icons.monitor
    }
  ]
};

export default operations;
