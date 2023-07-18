import {
  CioLogLevel,
  CustomerIO,
  CustomerIOEnv,
  CustomerioConfig,
} from 'customerio-reactnative';

export const initializeCustomerIoSDK = (sdkConfig) => {
  const env = new CustomerIOEnv();
  env.siteId = sdkConfig.siteId;
  env.apiKey = sdkConfig.apiKey;

  const config = new CustomerioConfig();
  config.enableInApp = true;

  if (sdkConfig.debugMode) {
    config.logLevel = CioLogLevel.debug;
  }
  if (sdkConfig.trackingApiUrl) {
    config.trackingApiUrl = sdkConfig.trackingApiUrl;
  }
  // Advanced SDK configurations only required by sample app, may not be required by most customer apps
  config.autoTrackDeviceAttributes = sdkConfig.trackDeviceAttributes;
  config.backgroundQueueMinNumberOfTasks = sdkConfig.bqMinNumberOfTasks;
  config.backgroundQueueSecondsDelay = sdkConfig.bqSecondsDelay;

  CustomerIO.initialize(env, config);
};

export const onUserLoggedIn = (user) => {
  CustomerIO.identify(user.email, {
    first_name: user.name,
    email: user.email,
  });
};

export const onUserLoggedOut = () => {
  CustomerIO.clearIdentify();
};

export const trackScreen = (screenName) => {
  CustomerIO.screen(screenName);
};

export const trackEvent = (eventName, propertyName, propertyValue) => {
  const data = {};
  if (propertyName) {
    data[propertyName] = propertyValue;
  }
  CustomerIO.track(eventName, data);
};

export const trackDeviceAttribute = (name, value) => {
  const data = {};
  data[name] = value;
  CustomerIO.setDeviceAttributes(data);
};

export const trackProfileAttribute = (name, value) => {
  const data = {};
  data[name] = value;
  CustomerIO.setProfileAttributes(data);
};

export const getPushPermissionStatus = () => {
  return CustomerIO.getPushPermissionStatus();
};

export const requestPushNotificationsPermission = (options) => {
  return CustomerIO.showPromptForPushNotifications(options);
};
