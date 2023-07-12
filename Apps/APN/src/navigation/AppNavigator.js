import {
  NavigationContainer,
  useNavigationContainerRef,
} from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { CustomerIO } from 'customerio-reactnative';
import React, { useRef } from 'react';
import Screen from '../data/enums/Screen';
import ScreenUtils from '../utils/ScreenUtils';

const Stack = createNativeStackNavigator();

const AppNavigator = (navigatorProps) => {
  const { initialRouteName, screenTrackingEnabled } = navigatorProps;
  const navigationRef = useNavigationContainerRef();
  const routeNameRef = useRef();

  const screens = Object.values(Screen);
  const deepLinkingSupportedScreens = screens.filter(
    (item) => item.supportDeepLinking === true
  );
  const linkingScreensConfig = {};
  for (const screen of deepLinkingSupportedScreens) {
    linkingScreensConfig[ScreenUtils.getComponent(screen)] = screen.name;
  }
  const linking = {
    prefixes: ['apn-rn-sample://'],
    config: {
      screens: linkingScreensConfig,
    },
  };

  const renderScreenComponents = () => {
    return screens.map((screen) => {
      const { key, name, options, component, componentPropsBuilder } =
        ScreenUtils.createNavigationStackProps(screen);

      return (
        <Stack.Screen key={key} name={name} options={options}>
          {(props) => component(componentPropsBuilder(navigatorProps, props))}
        </Stack.Screen>
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
