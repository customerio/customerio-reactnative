import {
  NavigationContainer,
  useNavigationContainerRef,
} from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { CustomerIO } from 'customerio-reactnative';
import React, { useRef } from 'react';
import Screen from '../data/enums/Screen';
import Attributes from '../screens/Attributes';
import CustomEvent from '../screens/CustomEvent';
import Dashboard from '../screens/Dashboard';
import Login from '../screens/Login';
import Settings from '../screens/Settings';
import ScreenUtils from '../utils/ScreenUtils';

const Stack = createNativeStackNavigator();

const AppNavigator = (navigatorProps) => {
  const { initialRouteName, screenTrackingEnabled } = navigatorProps;
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

      case Screen.CUSTOM_EVENTS:
        return CustomEvent;

      case Screen.DEVICE_ATTRIBUTES:
      case Screen.PROFILE_ATTRIBUTES:
        return Attributes;

      default:
        throw new Error(`Unknown screen: ${screen}`);
    }
  };

  const screens = Object.values(Screen);
  const deepLinkingSupportedScreens = screens.filter((item) => item.path);
  const linkingScreensConfig = {};
  for (const screen of deepLinkingSupportedScreens) {
    linkingScreensConfig[getComponentForScreen(screen)] = screen.name;
  }
  const linking = {
    prefixes: ['apn-rn-sample://'],
    config: {
      screens: linkingScreensConfig,
    },
  };

  const renderScreenComponents = () => {
    return screens.map((screen) => {
      const component = getComponentForScreen(screen);
      const { key, name, options, initialParams } =
        ScreenUtils.createNavigationStackProps(screen, navigatorProps);

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
        if (screenTrackingEnabled) {
          const previousRouteName = routeNameRef.current;
          const currentRouteName = navigationRef.getCurrentRoute().name;

          if (previousRouteName !== currentRouteName) {
            CustomerIO.screen(currentRouteName);
          }
          routeNameRef.current = currentRouteName;
        }
      }}
    >
      <Stack.Navigator initialRouteName={initialRouteName}>
        {renderScreenComponents()}
      </Stack.Navigator>
    </NavigationContainer>
  );
};

export default AppNavigator;
