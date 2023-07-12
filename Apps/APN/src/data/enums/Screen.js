const Screen = {
  LOGIN: { name: 'Login', path: 'login', supportDeepLinking: true },
  DASHBOARD: { name: 'Dashboard', path: 'dashboard', supportDeepLinking: true },
  SETTINGS: { name: 'Settings', path: 'settings', supportDeepLinking: true },
  CUSTOM_EVENTS: {
    name: 'Custom Event',
    path: 'events/custom',
    supportDeepLinking: false,
  },
  DEVICE_ATTRIBUTES: {
    name: 'Custom Device Attribute',
    path: 'attributes/device',
    supportDeepLinking: false,
  },
  PROFILE_ATTRIBUTES: {
    name: 'Custom Profile Attribute',
    path: 'attributes/profile',
    supportDeepLinking: false,
  },
};

export default Screen;
