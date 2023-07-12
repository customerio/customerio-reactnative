import {
  CioLogLevel,
  CustomerIO,
  CustomerIOEnv,
  CustomerioConfig,
} from 'customerio-reactnative';

class CustomerIOService {
  static async initializeSDK(sdkConfig) {
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

    CustomerIO.initialize(env, config);
  }

  static identifyUser(user) {
    CustomerIO.identify(user.email, {
      first_name: user.name,
      email: user.email,
      is_guest: user.isGuest,
    });
  }

  static clearUserIdentify() {
    CustomerIO.clearIdentify();
  }

  static sendEvent(eventName, propertyName, propertyValue) {
    const data = {};
    if (propertyName) {
      data[propertyName] = propertyValue;
    }
    CustomerIO.track(eventName, data);
  }

  static setDeviceAttribute(name, value) {
    const data = {};
    data[name] = value;
    CustomerIO.setDeviceAttributes(data);
  }

  static setProfileAttribute(name, value) {
    const data = {};
    data[name] = value;
    CustomerIO.setProfileAttributes(data);
  }
}

export default CustomerIOService;
