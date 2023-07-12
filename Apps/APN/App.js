import React, { useEffect, useState } from 'react';
import { ActivityIndicator } from 'react-native';
import Screen from './src/data/enums/Screen';
import CustomerIoSDKConfig from './src/data/sdk/CustomerIoSDKConfig';
import AppNavigator from './src/navigation/AppNavigator';
import CustomerIOService from './src/services/CustomerIOService';
import StorageService from './src/services/StorageService';

export default function App() {
  const [initialRouteName, setInitialRouteName] = useState(undefined);
  const [loading, setLoading] = useState(true);
  const [screenTrackingEnabled, setScreenTrackingEnabled] = useState(null);
  const [user, setUser] = useState(undefined);

  useEffect(() => {
    const storageService = new StorageService();

    const validateUserState = async () => {
      const value = await storageService.loadUser();
      setLoading(false);
      setUser(value);
      if (value) {
        setInitialRouteName(Screen.DASHBOARD.name);
        return;
      }
      setInitialRouteName(Screen.LOGIN.name);
    };

    const initializeCustomerIoSDK = async () => {
      const sdkConfig = CustomerIoSDKConfig.applyDefaultForUndefined(
        await storageService.loadSDKConfigurations()
      );
      await CustomerIOService.initializeSDK(sdkConfig);
      setScreenTrackingEnabled(sdkConfig.trackScreens);
    };

    validateUserState();
    initializeCustomerIoSDK();
  }, []);

  if (loading) {
    return <ActivityIndicator />;
  }

  return (
    <AppNavigator
      initialRouteName={initialRouteName}
      screenTrackingEnabled={screenTrackingEnabled}
      user={user}
    />
  );
}
