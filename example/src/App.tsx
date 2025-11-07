import React, { useEffect, useState } from 'react';

import { BodyText } from '@components';
import { NavigationCallbackContext } from '@navigation';
import { NavigationContainer } from '@react-navigation/native';
import { ContentNavigator } from '@screens';
import { Storage } from '@services';
import { appTheme } from '@utils';
import { CioConfig, CioPushPermissionStatus, CustomerIO, InAppMessageEvent, InAppMessageEventType } from 'customerio-reactnative';
import FlashMessage from 'react-native-flash-message';
import { SafeAreaProvider, SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { enableFreeze, enableScreens } from 'react-native-screens';
import { getEnvForApp } from './env';

// Enable native screen optimizations for better performance
enableScreens(true);        // Better native performance
enableFreeze(true);         // Let tabs "freeze" when not focused

// Wrapper component to provide FlashMessage with safe area insets
const SafeFlashMessage = () => {
  const insets = useSafeAreaInsets();
  return (
    <FlashMessage position={{ bottom: insets.bottom }} floating />
  );
};

export default function App({ appName }: { appName: string }) {
  const env = getEnvForApp(appName);
  Storage.setEnv(env);

  const [isLoading, setIsLoading] = useState(true);

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
        CustomerIO.initialize(cioConfig);
      }

      const logInAppEvent = (name: string, params: InAppMessageEvent) => {
        console.log(`[InAppEventListener] onEventReceived: ${name}, params: `, params);
      };

      const onInAppEventReceived = (
        eventName: string,
        eventParams: InAppMessageEvent,
      ) => {
        logInAppEvent(eventName, eventParams);

        const { deliveryId, messageId, actionValue, actionName } = eventParams;
        const data: Map<string, any> = new Map();
        data.set('event-name', eventName);
        data.set('delivery-id', deliveryId ?? 'NULL');
        data.set('message-id', messageId ?? 'NULL');
        if (actionName) {
          data.set('action-name', actionName);
        }
        if (actionValue) {
          data.set('action-value', actionValue);
        }

        CustomerIO.track('InAppEventListener', data);
      };

      const inAppMessagingSDK = CustomerIO.inAppMessaging;
      const inAppEventListener = inAppMessagingSDK.registerEventsListener((event) => {
        switch (event.eventType) {
          case InAppMessageEventType.messageShown:
            onInAppEventReceived('messageShown', event);
            break;

          case InAppMessageEventType.messageDismissed:
            onInAppEventReceived('messageDismissed', event);
            break;

          case InAppMessageEventType.errorWithMessage:
            onInAppEventReceived('errorWithMessage', event);
            break;

          case InAppMessageEventType.messageActionTaken:
            onInAppEventReceived('messageActionTaken', event);
            // Dismiss in app message if the action is 'dismiss' or 'close'
            if (event.actionValue === 'dismiss' || event.actionValue === 'close') {
              inAppMessagingSDK.dismissMessage();
            }
            break;

          default:
            onInAppEventReceived('unsupported event', event);
        }
      });

      // Remove listener once unmounted
      return () => {
        inAppEventListener.remove();
      };
    };
    loadFromStorage();
  }, [storage]);

  return (
    <SafeAreaProvider>
      <SafeAreaView style={{ flex: 1 }} edges={['bottom', 'left', 'right']}>
        {isLoading && <BodyText>Loading....</BodyText>}
        {!isLoading && (
          <NavigationCallbackContext.Provider
            value={{
              onSetConfig: (config) => {
                console.log('Initializing CustomerIO with config', config);
                CustomerIO.initialize(config);
              },
              onLogin: (user) => {
                console.log('Identifying user', user);
                CustomerIO.identify({ userId: user.traits.email ?? user.id, traits: user.traits });
              },
              onLogout: async () => {
                console.log('Clearing CustomerIO identify');
                CustomerIO.clearIdentify();
              },
              onTrackEvent: (eventPayload) => {
                console.log('Tracking event', eventPayload);
                CustomerIO.track(eventPayload.name, eventPayload.properties);
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
                console.log('Tracking screen change', screenName);
                CustomerIO.screen(screenName);
              },
              async onPushNotificationRequestPermissionButtonPress(): Promise<CioPushPermissionStatus> {
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

                return permission;
              },
            }}
          >
            <NavigationContainer
              theme={appTheme}
              linking={{
                prefixes: [
                  'amiapp-reactnative-apns://',
                  'amiapp-reactnative-fcm://',
                  'http://www.amiapp-reactnative-apns.com',
                  'https://www.amiapp-reactnative-apns.com',
                  'http://www.amiapp-reactnative-fcm.com',
                  'https://www.amiapp-reactnative-fcm.com',
                ],
                config: {
                  screens: linkingScreens,
                },
              }}
            >
              <ContentNavigator appName={appName} />
              <SafeFlashMessage />
            </NavigationContainer>
          </NavigationCallbackContext.Provider>
        )}
      </SafeAreaView>
    </SafeAreaProvider>
  );
}
