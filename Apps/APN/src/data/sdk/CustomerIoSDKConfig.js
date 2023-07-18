import Env from '../../../env';

export default class CustomerIoSDKConfig {
  constructor({
    siteId,
    apiKey,
    trackingUrl,
    bqSecondsDelay,
    bqMinNumberOfTasks,
    trackScreens,
    trackDeviceAttributes,
    debugMode,
  } = {}) {
    this.siteId = siteId;
    this.apiKey = apiKey;
    this.trackingUrl = trackingUrl;
    this.bqSecondsDelay = bqSecondsDelay;
    this.bqMinNumberOfTasks = bqMinNumberOfTasks;
    this.trackScreens = trackScreens;
    this.trackDeviceAttributes = trackDeviceAttributes;
    this.debugMode = debugMode;
  }

  static createDefault() {
    return new CustomerIoSDKConfig({
      siteId: Env.siteId,
      apiKey: Env.apiKey,
      trackingUrl: 'https://track-sdk.customer.io/',
      bqSecondsDelay: 30.0,
      bqMinNumberOfTasks: 10,
      trackScreens: true,
      trackDeviceAttributes: true,
      debugMode: true,
    });
  }

  static applyDefaultForUndefined(other) {
    const defaultConfig = this.createDefault();
    return new CustomerIoSDKConfig({
      siteId: other?.siteId ?? defaultConfig.siteId,
      apiKey: other?.apiKey ?? defaultConfig.apiKey,
      trackingUrl: other?.trackingUrl ?? defaultConfig.trackingUrl,
      bqSecondsDelay: other?.bqSecondsDelay ?? defaultConfig.bqSecondsDelay,
      bqMinNumberOfTasks:
        other?.bqMinNumberOfTasks ?? defaultConfig.bqMinNumberOfTasks,
      trackScreens: other?.trackScreens ?? defaultConfig.trackScreens,
      trackDeviceAttributes:
        other?.trackDeviceAttributes ?? defaultConfig.trackDeviceAttributes,
      debugMode: other?.debugMode ?? defaultConfig.debugMode,
    });
  }
}
