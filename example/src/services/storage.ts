import AsyncStorage from '@react-native-async-storage/async-storage';
import { User } from '@utils';
import {
  CioConfig,
  CioLocationTrackingMode,
  CioLogLevel,
  CioRegion,
  LiveActivityTemplate,
} from 'customerio-reactnative';
import { Env } from '../env';

const USER_STORAGE_KEY = 'user';
const CIO_CONFIG_STORAGE_KEY = 'cioConfig';

type Config = Partial<CioConfig>;

const createDefaultConfig = (env: Env | null | undefined): Config => {
  return {
    cdpApiKey: env?.API_KEY ?? '',
    inApp: {
      siteId: env?.SITE_ID ?? '',
      // The SDK ships no text of its own in the visual inbox, so these are the only strings it
      // can announce. A real app would resolve them through its own i18n so they follow the
      // user's language; they are hardcoded here only to keep the sample self-contained.
      notificationInboxAccessibilityLabels: {
        bell: 'Notifications',
        bellWithUnreadCount: 'Notifications, {count} unread',
        loadingIndicator: 'Loading inbox',
        emptyState: 'No notifications',
      },
    },
    region: CioRegion.US,
    logLevel: CioLogLevel.Debug,
    trackApplicationLifecycleEvents: true,
    location: {
      trackingMode: CioLocationTrackingMode.Manual,
    },
    // Opt into geofence monitoring. Runs automatically once enabled and implies the
    // Location module above.
    geofence: {},
    liveNotifications: {
      types: [
        LiveActivityTemplate.Segments,
        LiveActivityTemplate.CountdownTimer,
      ],
      customType: 'io.customer.livenotifications.custom.rideshare',
    },
  };
};

export class Storage {
  private user: User | null = null;
  private config: Config | null = null;
  private static defaultConfig: Config;

  static readonly setEnv = (env: Env) => {
    Storage.defaultConfig = createDefaultConfig(env);
  };

  static readonly instance: Storage = new Storage();

  private constructor() {}

  readonly loadAll = async () => {
    if (!this.user || !this.config) {
      await this.loadFromStorage();
    }
  };

  private readonly loadFromStorage = async () => {
    const userJsonPayload = await AsyncStorage.getItem(USER_STORAGE_KEY);
    const cioConfigJsonPayload = await AsyncStorage.getItem(
      CIO_CONFIG_STORAGE_KEY
    );

    this.user = userJsonPayload ? JSON.parse(userJsonPayload) : null;
    // Merge persisted config over defaults so newly added default keys (e.g. the
    // geofence opt-in) are present for installs saved before those keys existed.
    const savedConfig: Config | null = cioConfigJsonPayload
      ? JSON.parse(cioConfigJsonPayload)
      : null;
    this.config = savedConfig
      ? {
          ...Storage.defaultConfig,
          ...savedConfig,
          // `inApp` needs one more level of merging than the spread above gives it. A
          // config saved before the accessibility labels existed carries only `siteId`,
          // so a shallow spread replaces the defaults' `inApp` wholesale and silently
          // drops them — leaving every device that ever opened Settings demonstrating
          // the unlabeled inbox. Only merged when the saved config has `inApp` at all,
          // so disabling in-app messaging still persists.
          ...(savedConfig.inApp
            ? {
                inApp: { ...Storage.defaultConfig.inApp, ...savedConfig.inApp },
              }
            : {}),
        }
      : null;
  };

  readonly getUser = () => {
    return this.user;
  };

  readonly setUser = async (user: User) => {
    await AsyncStorage.setItem(USER_STORAGE_KEY, JSON.stringify(user));
    this.user = user;
  };

  readonly removeUser = async () => {
    this.user = null;
    await AsyncStorage.removeItem(USER_STORAGE_KEY);
  };

  readonly setCioConfig = async (cioConfig: CioConfig) => {
    this.config = cioConfig as Config;
    await AsyncStorage.setItem(
      CIO_CONFIG_STORAGE_KEY,
      JSON.stringify(this.config)
    );
  };

  readonly getCioConfig = (): CioConfig => {
    return this.config as CioConfig;
  };

  readonly getDefaultCioConfig = (): Partial<CioConfig> => {
    return Storage.defaultConfig;
  };

  readonly resetCioConfig = async () => {
    this.config = {
      ...Storage.defaultConfig,
      apiHost: this.config?.apiHost,
      cdnHost: this.config?.cdnHost,
    };

    await AsyncStorage.setItem(
      CIO_CONFIG_STORAGE_KEY,
      JSON.stringify(this.config)
    );
  };

  readonly clear = async () => {
    return AsyncStorage.clear();
  };
}
