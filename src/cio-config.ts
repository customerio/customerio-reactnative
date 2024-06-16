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

export type CioConfig = {
  cdpApiKey: string;
  siteId?: string;
  region?: CioRegion;
  logLevel?: CioLogLevel;
  trackApplicationLifecycleEvents?: boolean;
  enableInApp?: boolean;
};
