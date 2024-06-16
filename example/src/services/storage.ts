import AsyncStorage from '@react-native-async-storage/async-storage';
import { User } from '@utils';
import { CioConfig } from 'customerio-reactnative';

const USER_STORAGE_KEY = 'user';
const CIO_CONFIG_STORAGE_KEY = 'cioConfig';

export class Storage {
  private user: User | null = null;
  private cioConfig: CioConfig | null = null;

  static readonly instance: Storage = new Storage();

  private constructor() {}

  readonly loadAll = async () => {
    if (!this.user || !this.cioConfig) {
      await this.loadFromStorage();
    }
  };

  private readonly loadFromStorage = async () => {
    const userJsonPayload = await AsyncStorage.getItem(USER_STORAGE_KEY);
    const cioConfigJsonPayload = await AsyncStorage.getItem(
      CIO_CONFIG_STORAGE_KEY
    );
    this.user = userJsonPayload ? JSON.parse(userJsonPayload) : null;
    this.cioConfig = cioConfigJsonPayload
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
    await AsyncStorage.removeItem(USER_STORAGE_KEY);
    this.user = null;
  };

  readonly setCioConfig = async (config: CioConfig) => {
    await AsyncStorage.setItem(CIO_CONFIG_STORAGE_KEY, JSON.stringify(config));
    this.cioConfig = config;
  };

  readonly getCioConfig = () => {
    return this.cioConfig;
  };

  readonly clear = async () => {
    return AsyncStorage.clear();
  };
}
