import {
  CustomDeviceAttrScreenName,
  CustomProfileAttrScreenName,
  HomeScreenName,
  LoginScreenName,
  NavigationCallbackContext,
  NavigationStackParamList,
  SettingsScreenName,
  TrackScreenName,
} from '@navigation';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { screenStylingOptions } from '@utils';

import { SettingsNavButton } from '@components';
import {
  CustomDeviceAttrScreen,
  CustomProfileAttrScreen,
  HomeScreen,
  LogingScreen,
  SettingsScreen,
  TrackScreen,
} from '@screens';

import { Storage } from '@services';
import React, { useContext, useState } from 'react';
import { ScreensContext } from './context';

const Stack = createNativeStackNavigator<NavigationStackParamList>();

export const ContentNavigator = ({ moduleName }: { moduleName: string }) => {
  const [prevScreenName, setPrevScreenName] = useState<string | null>(null);
  const user = Storage.instance.getUser();
  const { onScreenChange } = useContext(NavigationCallbackContext);
  return (
    <ScreensContext.Provider value={{ moduleName }}>
      <Stack.Navigator
        initialRouteName={user ? HomeScreenName : LoginScreenName}
        screenOptions={screenStylingOptions}
        screenListeners={{
          state: (event) => {
            if (event.data.state.type === 'stack') {
              const currentRoute =
                event.data.state.routes[event.data.state.index];

              if (currentRoute.name !== prevScreenName) {
                if (prevScreenName) {
                  onScreenChange(currentRoute.name);
                }
                setPrevScreenName(currentRoute.name);
              }
            }
          },
        }}
      >
        <Stack.Screen name={SettingsScreenName} component={SettingsScreen} />
        <Stack.Screen
          name={HomeScreenName}
          component={HomeScreen}
          options={{
            headerRight: SettingsNavButton,
          }}
        />
        <Stack.Screen
          name={LoginScreenName}
          component={LogingScreen}
          options={{
            headerRight: SettingsNavButton,
          }}
        />
        <Stack.Screen name={TrackScreenName} component={TrackScreen} />
        <Stack.Screen
          name={CustomProfileAttrScreenName}
          component={CustomProfileAttrScreen}
        />
        <Stack.Screen
          name={CustomDeviceAttrScreenName}
          component={CustomDeviceAttrScreen}
        />
      </Stack.Navigator>
    </ScreensContext.Provider>
  );
};
