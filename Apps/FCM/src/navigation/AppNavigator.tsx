import {
  NavigationContainer,
  useNavigationContainerRef,
} from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import React, { useRef } from 'react';
import * as Colors from '../constants/Colors';
import { Screen, ScreenName } from '../data/enums/Screen';
import Attributes from '../screens/Attributes';
import CustomEvent from '../screens/CustomEvent';
import Dashboard from '../screens/Dashboard';
import Login from '../screens/Login';
import Settings from '../screens/Settings';
import { trackScreen } from '../services/CustomerIOService';
import { useCustomerIoSdkContext } from '../state/customerIoSdkState';
import { useUserStateContext } from '../state/userState';
import {
  isAuthenticatedViewOnly,
  isPublicViewAllowed,
  isUnauthenticatedViewOnly,
} from '../utils/navigation';

const Stack = createNativeStackNavigator();

interface NavigationStackProps {
  key: string;
  name: string;
  options: any;
  initialParams?: any;
}

const AppNavigator: React.FC = () => {
  const { config: sdkConfig } = useCustomerIoSdkContext();
  const { user } = useUserStateContext();
  const navigationRef = useNavigationContainerRef();
  const routeNameRef: React.MutableRefObject<string | undefined> = useRef();

  const getComponentForScreen = (
    screen: ScreenName,
  ): React.ComponentType<any> => {
    switch (screen) {
      case ScreenName.LOGIN:
        return Login;

      case ScreenName.DASHBOARD:
        return Dashboard;

      case ScreenName.SETTINGS:
        return Settings;

      case ScreenName.CUSTOM_EVENTS:
        return CustomEvent;

      case ScreenName.DEVICE_ATTRIBUTES:
      case ScreenName.PROFILE_ATTRIBUTES:
        return Attributes;

      default:
        throw new Error(`Unknown screen: ${screen}`);
    }
  };

  const createNavigationStackProps = (
    screenName: ScreenName,
  ): NavigationStackProps => {
    const screen = Screen[screenName];
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
          initialParams: {
            screen: screen,
          },
        };
        break;

      case Screen.CUSTOM_EVENTS:
      default:
        props = stackPropsDefault;
        break;
    }
    return props;
  };

  let initialRouteScreen: ScreenName;
  let linkingScreensConfig;
  let screens: Array<ScreenName>;

  if (user) {
    initialRouteScreen = ScreenName.DASHBOARD;
    screens = Object.values(ScreenName).filter(
      item => isPublicViewAllowed(item) || isAuthenticatedViewOnly(item),
    );
    linkingScreensConfig = {
      Dashboard: Screen[ScreenName.DASHBOARD].path,
      Settings: Screen[ScreenName.SETTINGS].path,
    };
  } else {
    initialRouteScreen = ScreenName.LOGIN;
    screens = Object.values(ScreenName).filter(
      item => isPublicViewAllowed(item) || isUnauthenticatedViewOnly(item),
    );
    linkingScreensConfig = {
      Login: Screen[ScreenName.LOGIN].path,
      Settings: Screen[ScreenName.SETTINGS].path,
    };
  }

  const linking = {
    prefixes: [
      'amiapp-reactnative-apns://',
      'http://www.amiapp-reactnative-apns.com',
      'https://www.amiapp-reactnative-apns.com',
    ],
    config: {
      screens: linkingScreensConfig,
    },
  };

  const renderScreenComponents = () => {
    return screens.map(screen => {
      const component = getComponentForScreen(screen);
      const { key, name, options, initialParams } =
        createNavigationStackProps(screen);

      return (
        <Stack.Screen
          key={key}
          name={name}
          options={options}
          getComponent={() => component}
          initialParams={initialParams}
        />
      );
    });
  };

  return (
    <NavigationContainer
      ref={navigationRef}
      linking={linking}
      onReady={() => {
        routeNameRef.current = navigationRef.getCurrentRoute()?.name;
      }}
      onStateChange={async () => {
        if (sdkConfig?.trackScreens === true) {
          const previousRouteName = routeNameRef.current;
          const currentRouteName = navigationRef.getCurrentRoute()?.name;

          if (currentRouteName && previousRouteName !== currentRouteName) {
            trackScreen(currentRouteName);
          }
          routeNameRef.current = currentRouteName;
        }
      }}>
      <Stack.Navigator initialRouteName={Screen[initialRouteScreen].name}>
        {renderScreenComponents()}
      </Stack.Navigator>
    </NavigationContainer>
  );
};

export default AppNavigator;
