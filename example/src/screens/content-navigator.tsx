import {
  CustomDeviceAttrScreenName,
  CustomProfileAttrScreenName,
  HomeScreenName,
  InboxMessagesScreenName,
  InlineExamplesScreenName,
  InternalSettingsScreenName,
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
  InboxMessagesScreen,
  InlineExamplesScreen,
  InternalSettingsScreen,
  LogingScreen,
  SettingsScreen,
  TrackScreen,
} from '@screens';

import { Storage } from '@services';
import React, { useContext, useState } from 'react';
import { ScreensContext } from './context';

const Stack = createNativeStackNavigator<NavigationStackParamList>();

export const ContentNavigator = ({ appName }: { appName: string }) => {
  const [prevScreenName, setPrevScreenName] = useState<string | null>(null);
  const user = Storage.instance.getUser();
  const { onScreenChange } = useContext(NavigationCallbackContext);
  return (
    <ScreensContext.Provider value={{ appName }}>
      <Stack.Navigator
        initialRouteName={user ? HomeScreenName : LoginScreenName}
        screenOptions={screenStylingOptions}
        screenListeners={{
          state: (event: any) => {
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
        <Stack.Screen
          name={SettingsScreenName}
          component={SettingsScreen}
          options={{
            headerBackButtonDisplayMode: 'minimal',
            headerBackVisible: true,
          }}
        />
        <Stack.Screen
          name={InternalSettingsScreenName}
          component={InternalSettingsScreen}
          options={{
            headerBackButtonDisplayMode: 'minimal',
            headerBackVisible: true,
          }}
        />
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
        <Stack.Screen
          name={TrackScreenName}
          component={TrackScreen}
          options={{
            headerBackButtonDisplayMode: 'minimal',
            headerBackVisible: true,
          }}
        />
        <Stack.Screen
          name={CustomProfileAttrScreenName}
          component={CustomProfileAttrScreen}
          options={{
            headerBackButtonDisplayMode: 'minimal',
            headerBackVisible: true,
          }}
        />
        <Stack.Screen
          name={CustomDeviceAttrScreenName}
          component={CustomDeviceAttrScreen}
          options={{
            headerBackButtonDisplayMode: 'minimal',
            headerBackVisible: true,
          }}
        />
        <Stack.Screen
          name={InlineExamplesScreenName}
          component={InlineExamplesScreen}
          options={{
            headerBackButtonDisplayMode: 'minimal',
            headerBackVisible: true,
          }}
        />
        <Stack.Screen
          name={InboxMessagesScreenName}
          component={InboxMessagesScreen}
          options={{
            headerBackButtonDisplayMode: 'minimal',
            headerBackVisible: true,
          }}
        />
      </Stack.Navigator>
    </ScreensContext.Provider>
  );
};
