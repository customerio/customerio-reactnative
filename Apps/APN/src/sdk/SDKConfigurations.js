import Env from '../env';

export default class SDKConfigurations {
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
    return new SDKConfigurations({
      siteId: Env.siteId,
      apiKey: Env.apiKey,
      trackingUrl: 'https://tracking.cio/',
      bqSecondsDelay: 30.0,
      bqMinNumberOfTasks: 10,
      trackScreens: true,
      trackDeviceAttributes: true,
      debugMode: true,
    });
  }
}
