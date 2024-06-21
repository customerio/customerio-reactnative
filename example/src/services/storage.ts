import AsyncStorage from '@react-native-async-storage/async-storage';
import { User } from '@utils';
import { CioConfig, CioLogLevel, CioRegion } from 'customerio-reactnative';

const USER_STORAGE_KEY = 'user';
const CIO_CONFIG_STORAGE_KEY = 'cioConfig';

export type QASettings = {
  cdnHost: string;
  apiHost: string;
};

type Config = Partial<CioConfig> & { qa: QASettings };

const defaultConfig: Config = {
  region: CioRegion.US,
  logLevel: CioLogLevel.Error,
  trackApplicationLifecycleEvents: true,
  qa: {
    cdnHost: 'https://cdp.customer.io/v1',
    apiHost: 'https://cdp.customer.io/v1',
  },
};

export class Storage {
  private user: User | null = null;
  private config: Config | null = null;

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
    this.config = { ...config, qa: config.qa ?? defaultConfig.qa };
    await AsyncStorage.setItem(
      CIO_CONFIG_STORAGE_KEY,
      JSON.stringify(this.config)
    );
  };

  readonly getCioConfig = (): CioConfig => {
    return this.config as CioConfig;
  };

  readonly getDefaultCioConfig = (): Partial<CioConfig> => {
    return defaultConfig;
  };

  readonly resetCioConfig = async () => {
    if (this.config === null) {
      this.config = defaultConfig;
    } else {
      this.config = { ...this.config, ...defaultConfig, qa: this.config.qa };
    }

    await AsyncStorage.setItem(
      CIO_CONFIG_STORAGE_KEY,
      JSON.stringify(this.config)
    );
  };

  readonly getQaConfig = (): QASettings => {
    return this.config?.qa ?? defaultConfig.qa;
  };

  readonly setQaConfig = async (qa: QASettings) => {
    if (this.config === null) {
      this.config = { ...defaultConfig, qa };
    } else {
      this.config = { ...this.config, qa };
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
