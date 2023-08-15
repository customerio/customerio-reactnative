import Env from '../../../env';

interface SDKConfigParams {
  siteId: string;
  apiKey: string;
  trackingUrl?: string;
  bqSecondsDelay?: number;
  bqMinNumberOfTasks?: number;
  trackScreens?: boolean;
  trackDeviceAttributes?: boolean;
  debugMode?: boolean;
}

export default class CustomerIoSDKConfig {
  siteId: string;
  apiKey: string;
  trackingUrl?: string;
  bqSecondsDelay?: number;
  bqMinNumberOfTasks?: number;
  trackScreens?: boolean;
  trackDeviceAttributes?: boolean;
  debugMode?: boolean;

  constructor(params: SDKConfigParams = { siteId: '', apiKey: '' }) {
    this.siteId = params.siteId;
    this.apiKey = params.apiKey;
    this.trackingUrl = params.trackingUrl;
    this.bqSecondsDelay = params.bqSecondsDelay;
    this.bqMinNumberOfTasks = params.bqMinNumberOfTasks;
    this.trackScreens = params.trackScreens;
    this.trackDeviceAttributes = params.trackDeviceAttributes;
    this.debugMode = params.debugMode;
  }

  static createDefault(): CustomerIoSDKConfig {
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

  static applyDefaultForUndefined(
    other?: SDKConfigParams,
  ): CustomerIoSDKConfig {
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
