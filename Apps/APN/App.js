import React, { useCallback, useEffect, useState } from 'react';
import { ActivityIndicator, SafeAreaView, StyleSheet } from 'react-native';
import CustomerIoSDKConfig from './src/data/sdk/CustomerIoSDKConfig';
import AppNavigator from './src/navigation/AppNavigator';
import {
  initializeCustomerIoSDK,
  onUserLoggedIn,
  onUserLoggedOut,
  registerInAppEventListener,
} from './src/services/CustomerIOService';
import StorageService from './src/services/StorageService';
import { CustomerIoSdkContext } from './src/state/customerIoSdkState';
import { UserStateContext } from './src/state/userState';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import {Notifications} from 'react-native-notifications';
import { CustomerIO } from 'customerio-reactnative';

export default function App() {
  const [loading, setLoading] = useState(true);
  const [userState, setUserState] = useState(undefined);
  const [customerIoSdkState, setCustomerIoSdk] = useState(undefined);

  useEffect(() => {
    const prepare = async () => {
      const storageService = new StorageService();
      const storage = await storageService.loadAll();

      updateUserState(storage.user);
      const sdkConfig = applyCustomerIoConfig(storage.sdkConfig);
      updateCustomerIoSdkState(sdkConfig);
      setLoading(false);
    };

    prepare();
    const inAppEventListener = registerInAppEventListener();

    // Remove listeners once unmounted
    return () => {
      inAppEventListener.remove();
    };
  }, [
    applyCustomerIoConfig,
    handleCustomerIoConfigChanged,
    updateCustomerIoSdkState,
    updateUserState,
  ]);

  // Setup react-native-notifications
  useEffect(() => {
    Notifications.registerRemoteNotifications();

    Notifications.events().registerNotificationReceivedForeground((notification: Notification, completion) => {
      console.log(`Non-Customer.io notification received in foreground: ${notification.title} : ${notification.body}`);

      completion({alert: true, sound: true, badge: true});
    });

    Notifications.events().registerNotificationOpened((notification: Notification, completion) => {
      console.log(`Non-Customer.io notification opened: ${notification.payload}`);

      CustomerIO.track("push clicked", {"push": notification.payload})

      completion();
    });
  });

  const updateCustomerIoSdkState = useCallback(
    (config) => {
      setCustomerIoSdk({
        config: config,
        onSdkConfigStateChanged: handleCustomerIoConfigChanged,
      });
    },
    [handleCustomerIoConfigChanged]
  );

  const handleCustomerIoConfigChanged = useCallback(
    async (config) => {
      const storageService = new StorageService();
      const sdkConfig = applyCustomerIoConfig(config);
      updateCustomerIoSdkState(sdkConfig);
      await storageService.saveSDKConfigurations(config);
    },
    [applyCustomerIoConfig, updateCustomerIoSdkState]
  );

  const applyCustomerIoConfig = useCallback((config) => {
    const sdkConfig = CustomerIoSDKConfig.applyDefaultForUndefined(config);
    initializeCustomerIoSDK(sdkConfig);
    return sdkConfig;
  }, []);

  const updateUserState = useCallback(
    (user) => {
      setUserState({
        user: user,
        onUserStateChanged: handleUserStateChanged,
      });
    },
    [handleUserStateChanged]
  );

  const handleUserStateChanged = useCallback(
    async (user) => {
      setLoading(true);
      const storageService = new StorageService();
      if (user) {
        // Save user to storage
        await storageService.saveUser(user);
        // Identify user to Customer.io
        onUserLoggedIn(user);
      } else {
        // Clear user identify from Customer.io
        onUserLoggedOut();
        // Clear user from storage
        await storageService.clearUser();
      }
      updateUserState(user);
      setLoading(false);
    },
    [updateUserState]
  );

  if (loading) {
    return <ActivityIndicator />;
  }

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <CustomerIoSdkContext.Provider value={customerIoSdkState}>
        <UserStateContext.Provider value={userState}>
          <SafeAreaView style={styles.container}>
            <AppNavigator />
          </SafeAreaView>
        </UserStateContext.Provider>
      </CustomerIoSdkContext.Provider>
    </GestureHandlerRootView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});
