import Login from '../../components/Login';
import * as Colors from '../constants/Colors';
import Screen from '../data/enums/Screen';
import Dashboard from '../screens/Dashboard';
import Settings from '../screens/Settings';

class ScreenUtils {
  static getLocation(screen) {
    if (screen === Screen.DASHBOARD || screen === Screen.LOGIN) {
      return screen.path;
    } else {
      return `${Screen.DASHBOARD.path}${screen.path}`;
    }
  }

  static getComponent(screen) {
    switch (screen) {
      case Screen.LOGIN:
        return Login;

      case Screen.DASHBOARD:
        return Dashboard;

      case Screen.SETTINGS:
        return Settings;

      case Screen.CUSTOM_EVENTS:
        return Settings;

      case Screen.DEVICE_ATTRIBUTES:
        return Settings;

      case Screen.PROFILE_ATTRIBUTES:
        return Settings;

      default:
        throw new Error(`Unknown screen: ${screen}`);
    }
  }

  static createStack(screen) {
    let stack = {
      name: screen.name,
      options: {
        gestureEnabled: true,
        headerStyle: {
          backgroundColor: Colors.TOP_BAR_BACKGROUND_COLOR,
        },
        title: '',
      },
      component: ScreenUtils.getComponent(screen),
    };
    switch (screen) {
      case Screen.LOGIN:
        stack.options = {
          ...stack.options,
          headerShown: false,
        };
        break;

      case Screen.DASHBOARD:
        stack.options = {
          ...stack.options,
          headerShown: false,
        };
        break;

      case Screen.SETTINGS:
        stack.options = {
          ...stack.options,
          title: 'Settings',
        };
        break;

      case Screen.CUSTOM_EVENTS:
      case Screen.DEVICE_ATTRIBUTES:
      case Screen.PROFILE_ATTRIBUTES:
      default:
        break;
    }
    return stack;
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
