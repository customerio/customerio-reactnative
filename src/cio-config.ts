export enum CioRegion {
  US = 'US',
  EU = 'EU',
}

export enum CioLogLevel {
  none = 'none',
  error = 'error',
  info = 'info',
  debug = 'debug',
}

export enum PushClickBehaviorAndroid {
  ResetTaskStack = 'RESET_TASK_STACK',
  ActivityPreventRestart = 'ACTIVITY_PREVENT_RESTART',
  ActivityNoFlags = 'ACTIVITY_NO_FLAGS',
}

export type CioConfig = {
  cdpApiKey: string;
  migrationSiteId?: string;
  region?: CioRegion;
  logLevel?: CioLogLevel;
  flushAt?: number;
  flushInterval?: number; 
  trackApplicationLifecycleEvents?: boolean;
  autoTrackDeviceAttributes?: boolean;
  pushClickBehaviorAndroid?: PushClickBehaviorAndroid;
  inApp?: {
    siteId: string;
 }
};
