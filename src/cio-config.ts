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

export type CioConfig = {
  cdpApiKey: string;
  migrationSiteId?: string;
  region?: CioRegion;
  logLevel?: CioLogLevel;
  flushAt?: number;
  flushInterval?: number; 
  trackApplicationLifecycleEvents?: boolean;
  autoTrackDeviceAttributes?: boolean;
  inApp?: {
    siteId: string;
 }
};
