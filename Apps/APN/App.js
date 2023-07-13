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
    const prepare = async () => {
      const storageService = new StorageService();
      const storage = await storageService.loadAll();
      setUser(storage.user);
      setLoading(false);
      if (storage.user) {
        setInitialRouteName(Screen.DASHBOARD.name);
      } else {
        setInitialRouteName(Screen.LOGIN.name);
      }

      const sdkConfig = CustomerIoSDKConfig.applyDefaultForUndefined(
        storage.sdkConfig
      );
      await CustomerIOService.initializeSDK(sdkConfig);
      setScreenTrackingEnabled(sdkConfig.trackScreens);
    };

    prepare();
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
