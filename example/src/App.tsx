import React, { useEffect } from 'react';

import { BodyText } from '@components';
import { NavigationCallbackContext } from '@navigation';
import { NavigationContainer } from '@react-navigation/native';
import { ContentNavigator } from '@screens';
import { Storage } from '@services';
import { appTheme } from '@utils';
import { CustomerIO } from 'customerio-reactnative';
import FlashMessage from 'react-native-flash-message';

export default function App() {
  const [isLoading, setIsLoading] = React.useState(true);
  const storage = Storage.instance;
  useEffect(() => {
    const loadFromStorage = async () => {
      await storage.loadAll();
      setIsLoading(false);

      const cioConfig = storage.getCioConfig();
      if (cioConfig) {
        console.log(
          'Initializing CustomerIO on app start with config',
          cioConfig
        );
        CustomerIO.initialize(cioConfig);
      }
    };
    loadFromStorage();
  }, [storage]);

  return (
    <>
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
              CustomerIO.identify(user.id, user.traits);
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
              if (CustomerIO.isInitialized()) {
                console.log('Tracking screen change', screenName);
                CustomerIO.screen(screenName);
              }
            },
          }}
        >
          <NavigationContainer theme={appTheme}>
            <ContentNavigator />
            <FlashMessage position="top" duration={4000} />
          </NavigationContainer>
        </NavigationCallbackContext.Provider>
      )}
    </>
  );
}
