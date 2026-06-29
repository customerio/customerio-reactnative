import AsyncStorage from '@react-native-async-storage/async-storage';
import { User } from '@utils';
import { CioConfig, CioLocationTrackingMode, CioLogLevel, CioRegion } from 'customerio-reactnative';
import { Env } from '../env';

const USER_STORAGE_KEY = 'user';
const CIO_CONFIG_STORAGE_KEY = 'cioConfig';

type Config = Partial<CioConfig>;

const createDefaultConfig = (env: Env | null | undefined): Config => {
  return {
    cdpApiKey: env?.API_KEY ?? '',
    inApp: {
      siteId: env?.SITE_ID ?? '',
    },
    region: CioRegion.US,
    logLevel: CioLogLevel.Debug,
    trackApplicationLifecycleEvents: true,
    location: {
      trackingMode: CioLocationTrackingMode.OnAppStart,
    },
    // Opt into geofence monitoring. Runs automatically once enabled and implies the
    // Location module above.
    geofence: {},
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
    this.config = cioConfigJsonPayload
      ? { ...Storage.defaultConfig, ...JSON.parse(cioConfigJsonPayload) }
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
