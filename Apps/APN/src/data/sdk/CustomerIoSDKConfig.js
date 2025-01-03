import { ScreenView } from 'customerio-reactnative';
import Env from '../../../env';

export default class CustomerIoSDKConfig {
  constructor({
    siteId,
    cdpApiKey,
    flushInterval,
    flushAt,
    screenViewUse,
    trackScreens,
    trackDeviceAttributes,
    debugMode,
    trackAppLifecycleEvents,
  } = {}) {
    this.siteId = siteId;
    this.cdpApiKey = cdpApiKey;
    this.flushInterval = flushInterval;
    this.flushAt = flushAt;
    this.screenViewUse = screenViewUse;
    this.trackAppLifecycleEvents = trackAppLifecycleEvents;
    this.trackScreens = trackScreens;
    this.trackDeviceAttributes = trackDeviceAttributes;
    this.debugMode = debugMode;
  }

  static createDefault() {
    return new CustomerIoSDKConfig({
      siteId: Env.siteId,
      cdpApiKey: Env.cdpApiKey,
      trackScreens: true,
      trackDeviceAttributes: true,
      trackAppLifecycleEvents: true,
      debugMode: true,
      screenViewUse: ScreenView.All.toString(),
    });
  }

  static applyDefaultForUndefined(other) {
    const defaultConfig = this.createDefault();
    return new CustomerIoSDKConfig({
      siteId: other?.siteId ?? defaultConfig.siteId,
      cdpApiKey: other?.cdpApiKey ?? defaultConfig.cdpApiKey,
      trackScreens: other?.trackScreens ?? defaultConfig.trackScreens,
      trackDeviceAttributes:
        other?.trackDeviceAttributes ?? defaultConfig.trackDeviceAttributes,
      debugMode: other?.debugMode ?? defaultConfig.debugMode,
      trackAppLifecycleEvents:
        other?.trackAppLifecycleEvents ?? defaultConfig.trackAppLifecycleEvents,
      screenViewUse: other?.screenViewUse ?? defaultConfig.screenViewUse,
    });
  }
}
