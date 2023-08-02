import { NavigationProp, ParamListBase } from '@react-navigation/native';
import { ScreenName } from '../data/enums/Screen';
import User from '../data/models/user';

export const navigateToScreen = (
  navigation: NavigationProp<ParamListBase>,
  screenName: ScreenName,
  params?: ParamListBase,
) => {
  navigation.navigate(screenName, params);
};

export const resetRoute = (
  navigation: NavigationProp<ParamListBase>,
  user?: User,
) => {
  let initialRoute: ScreenName;
  if (user) {
    initialRoute = ScreenName.DASHBOARD;
  } else {
    initialRoute = ScreenName.LOGIN;
  }
  navigation.reset({
    index: 0,
    routes: [{ name: initialRoute }],
  });
};

export const isAuthenticatedViewOnly = (screenName: ScreenName) => {
  return (
    !isUnauthenticatedViewOnly(screenName) && !isPublicViewAllowed(screenName)
  );
};

export const isUnauthenticatedViewOnly = (screenName: ScreenName) => {
  return screenName === ScreenName.LOGIN;
};

export const isPublicViewAllowed = (screenName: ScreenName) => {
  return screenName === ScreenName.SETTINGS;
};
