// assets
import { Profile2User, SecurityUser, Profile } from 'iconsax-reactjs';

// icons
const icons = {
  users: Profile2User,
  roles: SecurityUser,
  profile: Profile
};

// ==============================|| MENU ITEMS - USERS ||============================== //

const users = {
  id: 'group-users',
  title: 'User Management',
  type: 'group',
  children: [
    {
      id: 'users',
      title: 'Users',
      type: 'item',
      url: '/users',
      icon: icons.users
    },
    {
      id: 'roles',
      title: 'Roles',
      type: 'item',
      url: '/roles',
      icon: icons.roles
    },
    {
      id: 'profile',
      title: 'Profile',
      type: 'item',
      url: '/profile',
      icon: icons.profile
    }
  ]
};

export default users;
