import Screen from '../data/enums/Screen';

export const navigateToScreen = (navigation, screen, params = {}) => {
  navigation.navigate(screen.name, params);
};

export const isAuthenticatedViewOnly = (screen) => {
  return !isUnauthenticatedViewOnly(screen) && !isPublicViewAllowed(screen);
};

export const isUnauthenticatedViewOnly = (screen) => {
  return screen === Screen.LOGIN;
};

export const isPublicViewAllowed = (screen) => {
  return screen === Screen.SETTINGS;
};
