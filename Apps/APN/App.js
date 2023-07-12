import {
  CioLogLevel,
  CustomerIOEnv,
  CustomerioConfig,
} from 'customerio-reactnative';
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

      const env = new CustomerIOEnv();
      env.siteId = sdkConfig.siteId;
      env.apiKey = sdkConfig.apiKey;

      const config = new CustomerioConfig();
      if (sdkConfig.debugMode) {
        config.logLevel = CioLogLevel.debug;
      }
      if (sdkConfig.trackingApiUrl) {
        config.trackingApiUrl = sdkConfig.trackingApiUrl;
      }
      config.autoTrackDeviceAttributes = sdkConfig.trackDeviceAttributes;
      config.backgroundQueueMinNumberOfTasks = sdkConfig.bqMinNumberOfTasks;
      config.backgroundQueueSecondsDelay = sdkConfig.bqSecondsDelay;
      setScreenTrackingEnabled(sdkConfig.trackScreens);

      const customerIOService = new CustomerIOService();
      customerIOService.initializeSDK(env, config);
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
