import React, { useCallback, useEffect, useState } from 'react';
import { ActivityIndicator, SafeAreaView, StyleSheet } from 'react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import User from './src/data/models/user';
import CustomerIoSDKConfig from './src/data/sdk/CustomerIoSDKConfig';
import AppNavigator from './src/navigation/AppNavigator';
import {
  initializeCustomerIoSDK,
  onUserLoggedIn,
  onUserLoggedOut,
  registerInAppEventListener,
} from './src/services/CustomerIOService';
import { StorageService } from './src/services/StorageService';
import {
  CustomerIoSdkContext,
  CustomerIoSdkStateEmpty,
} from './src/state/customerIoSdkState';
import { UserStateContext, UserStateContextEmpty } from './src/state/userState';

export default function App() {
  const [loading, setLoading] = useState(true);
  const [userState, setUserState] = useState(UserStateContextEmpty);
  const [customerIoSdkState, setCustomerIoSdk] = useState(
    CustomerIoSdkStateEmpty,
  );

  const applyCustomerIoConfig = useCallback((config?: CustomerIoSDKConfig) => {
    const sdkConfig = CustomerIoSDKConfig.applyDefaultForUndefined(config);
    initializeCustomerIoSDK(sdkConfig);
    return sdkConfig;
  }, []);

  const handleUserStateChanged = useCallback(async (user?: User) => {
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
    setUserState({
      user: user,
      onUserStateChanged: handleUserStateChanged,
    });
    setLoading(false);
  }, []);

  const handleCustomerIoConfigChanged = useCallback(
    async (config: CustomerIoSDKConfig) => {
      const storageService = new StorageService();
      const sdkConfig = applyCustomerIoConfig(config);
      setCustomerIoSdk({
        config: sdkConfig,
        onSdkConfigStateChanged: handleCustomerIoConfigChanged,
      });
      await storageService.saveSDKConfigurations(config);
    },
    [applyCustomerIoConfig],
  );

  useEffect(() => {
    const prepare = async () => {
      const storageService = new StorageService();
      const storage = await storageService.loadAll();

      setUserState({
        user: storage.user,
        onUserStateChanged: handleUserStateChanged,
      });
      const sdkConfig = applyCustomerIoConfig(storage.sdkConfig);
      setCustomerIoSdk({
        config: sdkConfig,
        onSdkConfigStateChanged: handleCustomerIoConfigChanged,
      });
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
    handleUserStateChanged,
  ]);

  if (loading) {
    return <ActivityIndicator />;
  }

  return (
    <CustomerIoSdkContext.Provider value={customerIoSdkState}>
      <UserStateContext.Provider value={userState}>
        <SafeAreaView style={styles.container}>
          <GestureHandlerRootView style={styles.container}>
            <AppNavigator />
          </GestureHandlerRootView>
        </SafeAreaView>
      </UserStateContext.Provider>
    </CustomerIoSdkContext.Provider>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});
