import * as Colors from '../constants/Colors';
import Screen from '../data/enums/Screen';

class ScreenUtils {
  static navigateToScreen(navigation, screen) {
    navigation.navigate(screen.name);
  }

  static getLocation(screen) {
    if (screen === Screen.DASHBOARD || screen === Screen.LOGIN) {
      return screen.path;
    } else {
      return `${Screen.DASHBOARD.path}${screen.path}`;
    }
  }

  static createNavigationStackProps(screen) {
    let stackPropsDefault = {
      key: screen.name,
      name: screen.name,
      options: {
        gestureEnabled: true,
        headerShadowVisible: false,
        headerStyle: {
          backgroundColor: Colors.TOP_BAR_BACKGROUND_COLOR,
        },
        title: '',
      },
      componentPropsBuilder: (navigatorProps, stackProps) => {
        return { ...navigatorProps, ...stackProps };
      },
    };

    let props;
    switch (screen) {
      case Screen.LOGIN:
        props = {
          ...stackPropsDefault,
          options: {
            ...stackPropsDefault.options,
            headerShown: false,
          },
        };
        break;

      case Screen.DASHBOARD:
        props = {
          ...stackPropsDefault,
          options: {
            ...stackPropsDefault.options,
            headerShown: false,
          },
        };
        break;

      case Screen.SETTINGS:
        props = {
          ...stackPropsDefault,
          options: {
            ...stackPropsDefault.options,
            title: 'Settings',
          },
        };
        break;

      case Screen.DEVICE_ATTRIBUTES:
      case Screen.PROFILE_ATTRIBUTES:
        props = {
          ...stackPropsDefault,
          componentPropsBuilder: (navigatorProps, stackProps) => {
            return {
              ...stackPropsDefault.componentPropsBuilder(
                navigatorProps,
                stackProps
              ),
              screen,
            };
          },
        };
        break;

      case Screen.CUSTOM_EVENTS:
      default:
        props = stackPropsDefault;
        break;
    }
    return props;
  }

  static isAuthenticatedViewOnly(screen) {
    return (
      !ScreenUtils.isUnauthenticatedViewOnly(screen) &&
      !ScreenUtils.isPublicViewAllowed(screen)
    );
  }

  static isUnauthenticatedViewOnly(screen) {
    return screen === Screen.LOGIN;
  }

  static isPublicViewAllowed(screen) {
    return screen === Screen.SETTINGS;
  }
}

export default ScreenUtils;
