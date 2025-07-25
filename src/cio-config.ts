/** @public */
export enum CioRegion {
  US = 'US',
  EU = 'EU',
}

/**
 * Enum to define how CustomerIO SDK should handle screen view events.
 * - all: Send screen events to destinations for analytics purposes and to display in-app messages
 * - inApp: Only display in-app messages and not send screen events to destinations
 */
/** @public */
export enum ScreenView {
  All = 'all',
  InApp = 'inApp',
}

/** @public */
export enum CioLogLevel {
  None = 'none',
  Error = 'error',
  Info = 'info',
  Debug = 'debug',
}

/** @public */
export enum PushClickBehaviorAndroid {
  ResetTaskStack = 'RESET_TASK_STACK',
  ActivityPreventRestart = 'ACTIVITY_PREVENT_RESTART',
  ActivityNoFlags = 'ACTIVITY_NO_FLAGS',
}

/** @public */
export type CioConfig = {
  cdpApiKey: string;
  migrationSiteId?: string;
  region?: CioRegion;
  logLevel?: CioLogLevel;
  flushAt?: number;
  flushInterval?: number;
  screenViewUse?: ScreenView;
  trackApplicationLifecycleEvents?: boolean;
  autoTrackDeviceAttributes?: boolean;
  inApp?: {
    siteId: string;
  };
  push?: {
    android?: {
      pushClickBehavior?: PushClickBehaviorAndroid;
    };
  };
};

/** @public */
export type CioPushPermissionOptions = {
  ios?: {
    badge: boolean;
    sound: boolean;
  };
};

/** @public */
export enum CioPushPermissionStatus {
  Granted = 'GRANTED',
  Denied = 'DENIED',
  NotDetermined = 'NOTDETERMINED',
}
