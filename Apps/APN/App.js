import React, { useCallback, useEffect, useState } from 'react';
import { ActivityIndicator } from 'react-native';
import CustomerIoSDKConfig from './src/data/sdk/CustomerIoSDKConfig';
import AppNavigator from './src/navigation/AppNavigator';
import CustomerIOService from './src/services/CustomerIOService';
import StorageService from './src/services/StorageService';
import { CustomerIoSdkContext } from './src/state/customerIoSdkState';
import { UserStateContext } from './src/state/userState';

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
  }, [
    applyCustomerIoConfig,
    handleCustomerIoConfigChanged,
    updateCustomerIoSdkState,
    updateUserState,
  ]);

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
    CustomerIOService.initializeSDK(sdkConfig);
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
        CustomerIOService.identifyUser(user);
      } else {
        // Clear user identify from Customer.io
        CustomerIOService.clearUserIdentify();
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
    <CustomerIoSdkContext.Provider value={customerIoSdkState}>
      <UserStateContext.Provider value={userState}>
        <AppNavigator />
      </UserStateContext.Provider>
    </CustomerIoSdkContext.Provider>
  );
}
