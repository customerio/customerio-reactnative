interface Screen {
  name: string;
  path?: string; // The path property is optional
}

const Screen: { [key: string]: Screen } = {
  LOGIN: { name: 'Login', path: 'login' },
  DASHBOARD: { name: 'Dashboard', path: 'dashboard' },
  SETTINGS: { name: 'Settings', path: 'settings' },
  CUSTOM_EVENTS: { name: 'Custom Event' },
  DEVICE_ATTRIBUTES: { name: 'Custom Device Attribute' },
  PROFILE_ATTRIBUTES: { name: 'Custom Profile Attribute' },
};

export { Screen };
