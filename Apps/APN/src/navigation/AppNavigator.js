import {
  NavigationContainer,
  useNavigationContainerRef,
} from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { CustomerIO } from 'customerio-reactnative';
import React, { useRef } from 'react';
import CustomDataScreen from '../../components/CustomDataScreen';
import Dashboard from '../../components/Dashboard';
import Deeplinks from '../../components/Deeplink';
import Login from '../../components/Login';
import SettingsScreen from '../screens/SettingsScreen';

const Stack = createNativeStackNavigator();

const AppNavigator = ({ firstScreen, isScreenTrackingEnabled }) => {
  const navigationRef = useNavigationContainerRef();
  const routeNameRef = useRef();
  const config = {
    screens: {
      Deeplinks: 'deeplink',
    },
  };
  const linking = {
    prefixes: ['apn-rn-sample://'],
    config,
  };

  return (
    <NavigationContainer
      ref={navigationRef}
      linking={linking}
      onReady={() => {
        routeNameRef.current = navigationRef.getCurrentRoute().name;
      }}
      onStateChange={async () => {
        if (isScreenTrackingEnabled) {
          const previousRouteName = routeNameRef.current;
          const currentRouteName = navigationRef.getCurrentRoute().name;

          if (previousRouteName !== currentRouteName) {
            CustomerIO.screen(currentRouteName);
          }
          routeNameRef.current = currentRouteName;
        }
      }}
    >
      <Stack.Navigator initialRouteName={firstScreen}>
        <Stack.Screen
          name="Login"
          component={Login}
          options={{
            headerShown: false,
            gestureEnabled: false,
            gestureDirection: 'vertical',
          }}
        />
        <Stack.Screen
          name="Dashboard"
          component={Dashboard}
          options={{
            headerShown: false,
            gestureEnabled: false,
          }}
        />
        <Stack.Screen
          name="CustomDataScreen"
          component={CustomDataScreen}
          options={{
            title: '',
            headerStyle: {
              backgroundColor: '#ffffff',
            },
          }}
        />
        <Stack.Screen
          name="Deeplinks"
          component={Deeplinks}
          options={{
            title: '',
          }}
        />
        <Stack.Screen
          name="SettingsScreen"
          component={SettingsScreen}
          options={{
            title: '',
            headerStyle: {
              // backgroundColor: '#ffffff'
            },
          }}
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
};

export default AppNavigator;
