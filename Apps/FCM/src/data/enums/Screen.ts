interface ScreenValue {
  name: string;
  path?: string;
}

enum ScreenName {
  LOGIN = 'LOGIN',
  DASHBOARD = 'DASHBOARD',
  SETTINGS = 'SETTINGS',
  CUSTOM_EVENTS = 'CUSTOM_EVENTS',
  DEVICE_ATTRIBUTES = 'DEVICE_ATTRIBUTES',
  PROFILE_ATTRIBUTES = 'PROFILE_ATTRIBUTES',
}

const Screen: Record<ScreenName, ScreenValue> = {
  [ScreenName.LOGIN]: { name: 'Login', path: 'login' },
  [ScreenName.DASHBOARD]: { name: 'Dashboard', path: 'dashboard' },
  [ScreenName.SETTINGS]: { name: 'Settings', path: 'settings' },
  [ScreenName.CUSTOM_EVENTS]: { name: 'Custom Event' },
  [ScreenName.DEVICE_ATTRIBUTES]: { name: 'Custom Device Attribute' },
  [ScreenName.PROFILE_ATTRIBUTES]: { name: 'Custom Profile Attribute' },
};

export { Screen, ScreenName };
