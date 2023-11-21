import { CioLogLevel, Region } from './CustomerioEnum';
import { PushClickBehaviorAndroid } from './types';

/**
 * Configure package using CustomerioConfig
 *
 * Usecase:
 *
 * const configData = new CustomerioConfig()
 * configData.logLevel = CioLogLevel.debug
 * configData.autoTrackDeviceAttributes = true
 * CustomerIO.config(data)
 */
class CustomerioConfig {
  logLevel: CioLogLevel = CioLogLevel.error;
  autoTrackDeviceAttributes: boolean = true;
  enableInApp: boolean = false;
  trackingApiUrl: string = '';
  autoTrackPushEvents: boolean = true;
  backgroundQueueMinNumberOfTasks: number = 10;
  backgroundQueueSecondsDelay: number = 30;
  pushClickBehaviorAndroid: PushClickBehaviorAndroid =
  PushClickBehaviorAndroid.ActivityPreventRestart;
}

class CustomerIOEnv {
  siteId: string = '';
  apiKey: string = '';
  region: Region = Region.US;
  writeKey: string = '';
  /**
   * @deprecated since version 2.0.2
   *
   * organizationId is no longer needed and will be removed in future releases.
   * Please remove organizationId from code and enable in-app messaging using {CustomerioConfig.enableInApp}.
   */
  organizationId: string = '';
}

class PackageConfig {
  version: string = '';
  source: string = '';
}

export { CustomerioConfig, CustomerIOEnv, PackageConfig };
