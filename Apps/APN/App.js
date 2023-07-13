import React, { useEffect, useState } from 'react';
import { ActivityIndicator } from 'react-native';
import Screen from './src/data/enums/Screen';
import CustomerIoSDKConfig from './src/data/sdk/CustomerIoSDKConfig';
import AppNavigator from './src/navigation/AppNavigator';
import CustomerIOService from './src/services/CustomerIOService';
import StorageService from './src/services/StorageService';
import { UserStateContext } from './src/state/userState';

export default function App() {
  const [initialRouteName, setInitialRouteName] = useState(undefined);
  const [loading, setLoading] = useState(true);
  const [screenTrackingEnabled, setScreenTrackingEnabled] = useState(null);
  const [userState, setUserState] = useState(undefined);

  useEffect(() => {
    const prepare = async () => {
      const storageService = new StorageService();
      const storage = await storageService.loadAll();
      updateUserState(storage.user);
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
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const updateUserState = async (user) => {
    setUserState({
      user: user,
      onUserStateChanged: handleUserStateChanged,
    });
  };

  const handleUserStateChanged = async (user) => {
    setLoading(true);
    const storageService = new StorageService();
    if (user) {
      // Save user to storage
      await storageService.saveUser(user);
      // Identify user to Customer.io
      CustomerIOService.identifyUser(user);
      setInitialRouteName(Screen.DASHBOARD.name);
    } else {
      // Clear user identify from Customer.io
      CustomerIOService.clearUserIdentify();
      // Clear user from storage
      await storageService.clearUser();
      setInitialRouteName(Screen.LOGIN.name);
    }
    setLoading(false);
    updateUserState(user);
  };

  if (loading) {
    return <ActivityIndicator />;
  }

  return (
    <UserStateContext.Provider value={userState}>
      <AppNavigator
        initialRouteName={initialRouteName}
        screenTrackingEnabled={screenTrackingEnabled}
      />
    </UserStateContext.Provider>
  );
}
