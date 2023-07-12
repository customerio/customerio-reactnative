const Screen = {
  login: {
    name: 'Login',
    path: 'login',
  },
  dashboard: {
    name: 'Dashboard',
    path: 'dashboard',
  },
  settings: {
    name: 'Settings',
    path: 'settings',
  },
  customEvents: {
    name: 'Custom Event',
    path: 'events/custom',
  },
  deviceAttributes: {
    name: 'Custom Device Attribute',
    path: 'attributes/device',
  },
  profileAttributes: {
    name: 'Custom Profile Attribute',
    path: 'attributes/profile',
  },
};

const ScreenFactory = (routerLocation) => {
  const screen = Screen[routerLocation];
  if (screen === undefined) {
    return null;
  } else {
    return screen;
  }
};

const ScreenProperties = {
  isAuthenticatedViewOnly: (screen) => {
    return !screen.isUnauthenticatedViewOnly && !screen.isPublicViewAllowed;
  },
  isUnauthenticatedViewOnly: (screen) => {
    return screen === Screen.login;
  },
  isPublicViewAllowed: (screen) => {
    return screen === Screen.settings;
  },
};

export { Screen, ScreenFactory, ScreenProperties };
