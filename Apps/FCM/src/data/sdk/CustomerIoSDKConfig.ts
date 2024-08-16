import Env from '../../../env';

interface SDKConfigParams {
  siteId: string;
  cdpApiKey: string;
  bqSecondsDelay?: number;
  bqMinNumberOfTasks?: number;
  trackScreens?: boolean;
  trackDeviceAttributes?: boolean;
  debugMode?: boolean;
  trackAppLifecycleEvents?: boolean;
}

export default class CustomerIoSDKConfig {
  siteId: string;
  cdpApiKey: string;
  bqSecondsDelay?: number;
  bqMinNumberOfTasks?: number;
  trackScreens?: boolean;
  trackDeviceAttributes?: boolean;
  trackAppLifecycleEvents?: boolean;
  debugMode?: boolean;

  constructor(params: SDKConfigParams = { siteId: '', cdpApiKey: '' }) {
    this.siteId = params.siteId;
    this.cdpApiKey = params.cdpApiKey;
    this.bqSecondsDelay = params.bqSecondsDelay;
    this.bqMinNumberOfTasks = params.bqMinNumberOfTasks;
    this.trackScreens = params.trackScreens;
    this.trackDeviceAttributes = params.trackDeviceAttributes;
    this.trackAppLifecycleEvents = params.trackAppLifecycleEvents;
    this.debugMode = params.debugMode;
  }

  static createDefault(): CustomerIoSDKConfig {
    return new CustomerIoSDKConfig({
      siteId: Env.siteId,
      cdpApiKey: Env.cdpApiKey,
      bqSecondsDelay: 30.0,
      bqMinNumberOfTasks: 10,
      trackScreens: true,
      trackDeviceAttributes: true,
      debugMode: true,
    });
  }

  static applyDefaultForUndefined(
    other?: SDKConfigParams,
  ): CustomerIoSDKConfig {
    const defaultConfig = this.createDefault();
    return new CustomerIoSDKConfig({
      siteId: other?.siteId ?? defaultConfig.siteId,
      cdpApiKey: other?.cdpApiKey ?? defaultConfig.cdpApiKey,
      bqSecondsDelay: other?.bqSecondsDelay ?? defaultConfig.bqSecondsDelay,
      bqMinNumberOfTasks:
        other?.bqMinNumberOfTasks ?? defaultConfig.bqMinNumberOfTasks,
      trackScreens: other?.trackScreens ?? defaultConfig.trackScreens,
      trackDeviceAttributes:
        other?.trackDeviceAttributes ?? defaultConfig.trackDeviceAttributes,
      debugMode: other?.debugMode ?? defaultConfig.debugMode,
      trackAppLifecycleEvents:  other?.trackAppLifecycleEvents ?? defaultConfig.trackAppLifecycleEvents,
    });
  }
}
