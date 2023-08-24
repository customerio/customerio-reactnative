import { NavigationProp, ParamListBase } from '@react-navigation/native';
import { Screen } from '../data/enums/Screen';
import User from '../data/models/user';

export const navigateToScreen = (
  navigation: NavigationProp<ParamListBase>,
  screen: Screen,
  params?: ParamListBase,
) => {
  navigation.navigate(screen.name, params);
};

export const resetRoute = (
  navigation: NavigationProp<ParamListBase>,
  user?: User,
) => {
  let initialRoute: Screen;
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

export const isAuthenticatedViewOnly = (screen: Screen) => {
  return !isUnauthenticatedViewOnly(screen) && !isPublicViewAllowed(screen);
};

export const isUnauthenticatedViewOnly = (screen: Screen) => {
  return screen === Screen.LOGIN;
};

export const isPublicViewAllowed = (screen: Screen) => {
  return screen === Screen.SETTINGS;
};
