import AsyncStorage from '@react-native-async-storage/async-storage';
import { User } from '@utils';
import { CioConfig, CioLogLevel, CioRegion } from 'customerio-reactnative';
import { Env } from '../env';

const USER_STORAGE_KEY = 'user';
const CIO_CONFIG_STORAGE_KEY = 'cioConfig';
export type InternalSettings = {
  cdnHost: string;
  apiHost: string;
};

type Config = Partial<CioConfig> & { qa?: InternalSettings };

const createDefaultConfig = (env: Env | null | undefined): Config => {
  return {
    cdpApiKey: env?.API_KEY ?? '',
    inApp: {
      siteId: env?.SITE_ID ?? '',
    },
    region: CioRegion.US,
    logLevel: CioLogLevel.Debug,
    trackApplicationLifecycleEvents: true,
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
    this.config = cioConfigJsonPayload
      ? JSON.parse(cioConfigJsonPayload)
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
    const config = cioConfig as Config;
    this.config = {
      ...config,
      qa: config.qa ?? Storage.defaultConfig.qa,
    };
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
    if (this.config === null) {
      this.config = Storage.defaultConfig;
    } else {
      this.config = {
        ...this.config,
        ...Storage.defaultConfig,
        qa: this.config.qa,
      };
    }

    await AsyncStorage.setItem(
      CIO_CONFIG_STORAGE_KEY,
      JSON.stringify(this.config)
    );
  };

  readonly getInternalDevConfig = (): InternalSettings | undefined => {
    return this.config?.qa ?? Storage.defaultConfig.qa;
  };

  readonly setInternalDevConfig = async (
    internalSettings: InternalSettings
  ) => {
    if (this.config === null) {
      this.config = { ...Storage.defaultConfig, qa: internalSettings };
    } else {
      this.config = { ...this.config, qa: internalSettings };
    }

    await AsyncStorage.setItem(
      CIO_CONFIG_STORAGE_KEY,
      JSON.stringify(this.config)
    );
  };

  readonly clear = async () => {
    return AsyncStorage.clear();
  };
}
