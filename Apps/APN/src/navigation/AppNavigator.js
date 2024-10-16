import {
  NavigationContainer,
  useNavigationContainerRef,
} from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import React, { useRef } from 'react';
import * as Colors from '../constants/Colors';
import Screen from '../data/enums/Screen';
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
import InternalSettings from '../screens/InternalSettings';

const Stack = createNativeStackNavigator();

const AppNavigator = () => {
  const { config: sdkConfig } = useCustomerIoSdkContext();
  const { user } = useUserStateContext();
  const navigationRef = useNavigationContainerRef();
  const routeNameRef = useRef();

  const getComponentForScreen = (screen) => {
    switch (screen) {
      case Screen.LOGIN:
        return Login;

      case Screen.DASHBOARD:
        return Dashboard;

      case Screen.SETTINGS:
        return Settings;

      case Screen.INTERNAL_SETTINGS:
        return InternalSettings;

      case Screen.CUSTOM_EVENTS:
        return CustomEvent;

      case Screen.DEVICE_ATTRIBUTES:
      case Screen.PROFILE_ATTRIBUTES:
        return Attributes;

      default:
        throw new Error(`Unknown screen: ${screen}`);
    }
  };

  const createNavigationStackProps = (screen) => {
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

      case Screen.INTERNAL_SETTINGS:
        props = {
          ...stackPropsDefault,
          options: {
            ...stackPropsDefault.options,
            title: 'Internal Settings',
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

  let initialRouteScreen;
  let linkingScreensConfig;
  let screens;

  if (user) {
    initialRouteScreen = Screen.DASHBOARD;
    screens = Object.values(Screen).filter(
      (item) => isPublicViewAllowed(item) || isAuthenticatedViewOnly(item)
    );
    linkingScreensConfig = {
      Dashboard: Screen.DASHBOARD.path,
      Settings: Screen.SETTINGS.path,
    };
  } else {
    initialRouteScreen = Screen.LOGIN;
    screens = Object.values(Screen).filter(
      (item) => isPublicViewAllowed(item) || isUnauthenticatedViewOnly(item)
    );
    linkingScreensConfig = {
      Login: Screen.LOGIN.path,
      Settings: Screen.SETTINGS.path,
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
    return screens.map((screen) => {
      const component = getComponentForScreen(screen);
      const { key, name, options, initialParams } =
        createNavigationStackProps(screen);

      return (
        <Stack.Screen
          key={key}
          name={name}
          options={options}
          component={component}
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
        routeNameRef.current = navigationRef.getCurrentRoute().name;
      }}
      onStateChange={async () => {
        if (sdkConfig.trackScreens) {
          const previousRouteName = routeNameRef.current;
          const currentRouteName = navigationRef.getCurrentRoute().name;

          if (previousRouteName !== currentRouteName) {
            trackScreen(currentRouteName);
          }
          routeNameRef.current = currentRouteName;
        }
      }}
    >
      <Stack.Navigator initialRouteName={initialRouteScreen.name}>
        {renderScreenComponents()}
      </Stack.Navigator>
    </NavigationContainer>
  );
};

export default AppNavigator;
