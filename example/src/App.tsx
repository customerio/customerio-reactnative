import React, { useEffect, useState } from 'react';

import { BodyText } from '@components';
import { NavigationCallbackContext } from '@navigation';
import { NavigationContainer } from '@react-navigation/native';
import { ContentNavigator } from '@screens';
import { Storage } from '@services';
import { appTheme } from '@utils';
import { CioConfig, CioPushPermissionStatus, CustomerIO } from 'customerio-reactnative';
import FlashMessage, { showMessage } from 'react-native-flash-message';


// Define minimal type inline since we're bypassing env.ts
type SimpleEnv = {
  API_KEY: string;
  SITE_ID: string;
  buildTimestamp?: number;
};

export default function App({ appName }: { appName: string }) {
  // BYPASS ENVIRONMENT FILE COMPLETELY - USE HARDCODED VALUES
  const hardcodedEnv: SimpleEnv = {
    API_KEY: 'hardcoded_dummy_api_key_12345',
    SITE_ID: 'hardcoded_dummy_site_id_67890',
    buildTimestamp: 1699999999,
  };
  
  // Simple debug string
  const debugInfo = `App="${appName}" 🔧HARDCODED_ENV 🔑${hardcodedEnv.API_KEY.substring(0, 10)}...`;
  
  // Set the hardcoded environment
  Storage.setEnv(hardcodedEnv);

  const [isLoading, setIsLoading] = React.useState(true);

  const storage = Storage.instance;
  const user = storage.getUser();
  const linkingScreens = user
    ? {
        Home: 'home',
        Settings: 'settings',
      }
    : {
        Login: 'login',
        Settings: 'settings',
      };
  useEffect(() => {
    const loadFromStorage = async () => {
      await storage.loadAll();
      setIsLoading(false);

      if (!storage.getCioConfig()) {
        storage.setCioConfig(storage.getDefaultCioConfig() as CioConfig);
      }
      const cioConfig = storage.getCioConfig();
      if (cioConfig) {
        console.log(
          'Initializing CustomerIO on app start with config',
          cioConfig
        );
        try {
          CustomerIO.initialize(cioConfig);
          console.log('CustomerIO initialized successfully');
        } catch (error) {
          console.error('Failed to initialize CustomerIO:', error);
          // Don't throw - let the app continue to run
        }
      } else {
        console.error('No CustomerIO config found in storage');
      }
    };
    loadFromStorage();
  }, [storage]);

  return (
    <>
      {isLoading && <BodyText>Loading....</BodyText>}
      {/* Debug info - remove this after fixing the issue */}
      {!isLoading && (
        <BodyText style={{fontSize: 10, backgroundColor: 'yellow'}}>
          {debugInfo}
        </BodyText>
      )}
      {!isLoading && (
        <NavigationCallbackContext.Provider
          value={{
            onSetConfig: (config) => {
              console.log('Initializing CustomerIO with config', config);
              CustomerIO.initialize(config);
            },
            onLogin: (user) => {
              console.log('Identifying user', user);
              CustomerIO.identify({ userId: user.id, traits: user.traits });
            },
            onLogout: async () => {
              console.log('Clearing CustomerIO identify');
              CustomerIO.clearIdentify();
            },
            onTrackEvent: (eventPayload) => {
              if (CustomerIO.isInitialized()) {
                console.log('Tracking event', eventPayload);
                CustomerIO.track(eventPayload.name, eventPayload.properties);
              } else {
                showMessage({
                  message: 'CustomerIO not initialized',
                  description: 'Please set the CustomerIO config',
                  type: 'danger',
                });
              }
            },
            onProfileAttributes(attributes) {
              console.log('Setting profile attributes', attributes);
              CustomerIO.setProfileAttributes(attributes);
            },
            onDeviceAttributes(attributes) {
              console.log('Setting device attributes', attributes);
              CustomerIO.setDeviceAttributes(attributes);
            },
            onScreenChange(screenName) {
              // See 'src/screens/content-navigator.tsx' for the how we implemented screen auto-tracking
              if (CustomerIO.isInitialized()) {
                console.log('Tracking screen change', screenName);
                CustomerIO.screen(screenName);
              }
            },
            async onPushNotificationRequestPermisionButtonPress(): Promise<void> {
              console.log('Requesting push notification permission');
              const permission =
                await CustomerIO.pushMessaging.showPromptForPushNotifications({
                  ios: { sound: true, badge: true },
                });

              switch (permission) {
                case CioPushPermissionStatus.Granted:
                  console.log(
                    `Push notifications are now enabled on this device`
                  );
                  break;
                case CioPushPermissionStatus.Denied:
                case CioPushPermissionStatus.NotDetermined:
                  console.log(
                    `Push notifications are denied on this device. Please allow notification permission from settings to receive push on this device`
                  );
                  break;
              }
            },
          }}
        >
          <NavigationContainer
            theme={appTheme}
            linking={{
              prefixes: [
                'amiapp-reactnative-apns://',
                'http://www.amiapp-reactnative-apns.com',
                'https://www.amiapp-reactnative-apns.com',
              ],
              config: {
                screens: linkingScreens,
              },
            }}
          >
            <ContentNavigator appName={appName} />
            <FlashMessage position="top" duration={4000} />
          </NavigationContainer>
        </NavigationCallbackContext.Provider>
      )}
    </>
  );
}
