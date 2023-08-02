import Screen from '../data/enums/Screen';

export const navigateToScreen = (navigation, screen, params = {}) => {
  navigation.navigate(screen.name, params);
};

export const resetRoute = (navigation, user) => {
  let initialRoute;
  if (user) {
    initialRoute = Screen.DASHBOARD;
  } else {
    initialRoute = Screen.LOGIN;
  }
  navigation.reset({
    index: 0,
    routes: [{ name: initialRoute.name }],
  });
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
