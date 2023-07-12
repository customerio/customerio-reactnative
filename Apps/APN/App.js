import {
  CioLogLevel,
  CustomerIOEnv,
  CustomerioConfig,
} from 'customerio-reactnative';
import React, { useEffect, useState } from 'react';
import { ActivityIndicator } from 'react-native';
import CustomerIoSDKConfig from './src/data/sdk/CustomerIoSDKConfig';
import AppNavigator from './src/navigation/AppNavigator';
import CustomerIOService from './src/services/CustomerIOService';
import StorageService from './src/services/StorageService';

export default function App() {
  const storageService = new StorageService();

  const [firstScreen, setFirstScreen] = useState(undefined);
  const [loading, setLoading] = useState(true);
  const [isScreenTrackingEnabled, setScreenTrackingEnabled] = useState(null);

  useEffect(() => {
    validateUserState();
    initializeCustomerIoSDK();

    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const validateUserState = async () => {
    const user = await storageService.loadUser();
    setLoading(false);
    if (user) {
      setFirstScreen('Dashboard');
      return;
    }
    setFirstScreen('Login');
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

  if (loading) {
    return <ActivityIndicator />;
  }

  return (
    <AppNavigator
      firstScreen={firstScreen}
      isScreenTrackingEnabled={isScreenTrackingEnabled}
    />
  );
}
