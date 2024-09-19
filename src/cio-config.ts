export enum CioRegion {
  US = 'US',
  EU = 'EU',
}

export enum CioLogLevel {
  None = 'none',
  Error = 'error',
  Info = 'info',
  Debug = 'debug',
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

export type CioPushPermissionOptions = {
  ios?: {
    badge: boolean;
    sound: boolean;
  };
}

export enum CioPushPermissionStatus {
  Granted = 'Granted',
  Denied = 'Denied',
  NotDetermined = 'NotDetermined',
}
