import Env from '../../../env';

interface SDKConfigParams {
  siteId: string;
  cdpApiKey: string;
  flushInterval?: number;
  flushAt?: number;
  trackScreens?: boolean;
  trackDeviceAttributes?: boolean;
  debugMode?: boolean;
  trackAppLifecycleEvents?: boolean;
}

export default class CustomerIoSDKConfig {
  siteId: string;
  cdpApiKey: string;
  flushInterval?: number;
  flushAt?: number;
  trackScreens?: boolean;
  trackDeviceAttributes?: boolean;
  trackAppLifecycleEvents?: boolean;
  debugMode?: boolean;

  constructor(params: SDKConfigParams = { siteId: '', cdpApiKey: '' }) {
    this.siteId = params.siteId;
    this.cdpApiKey = params.cdpApiKey;
    this.flushInterval = params.flushInterval;
    this.flushAt = params.flushAt;
    this.trackScreens = params.trackScreens;
    this.trackDeviceAttributes = params.trackDeviceAttributes;
    this.trackAppLifecycleEvents = params.trackAppLifecycleEvents;
    this.debugMode = params.debugMode;
  }

  static createDefault(): CustomerIoSDKConfig {
    return new CustomerIoSDKConfig({
      siteId: Env.siteId,
      cdpApiKey: Env.cdpApiKey,
      trackScreens: true,
      trackDeviceAttributes: true,
      trackAppLifecycleEvents: true,
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
      trackScreens: other?.trackScreens ?? defaultConfig.trackScreens,
      trackDeviceAttributes:
        other?.trackDeviceAttributes ?? defaultConfig.trackDeviceAttributes,
      debugMode: other?.debugMode ?? defaultConfig.debugMode,
      trackAppLifecycleEvents:  other?.trackAppLifecycleEvents ?? defaultConfig.trackAppLifecycleEvents,
    });
  }
}
