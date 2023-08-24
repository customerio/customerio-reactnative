import AsyncStorage from '@react-native-async-storage/async-storage';
import { SDK_CONFIG, USER_STATE } from '../constants/StorageConstants';
import User from '../data/models/user';
import CustomerIoSDKConfig from '../data/sdk/CustomerIoSDKConfig';

export interface StorageValues {
  sdkConfig?: CustomerIoSDKConfig;
  user?: User;
}

export class StorageService {
  async loadFromStorage(key: string): Promise<string | null> {
    try {
      return await AsyncStorage.getItem(key);
    } catch (e) {
      console.log(e);
      return null;
    }
  }

  removeFromStorage(key: string) {
    try {
      return AsyncStorage.removeItem(key);
    } catch (e) {
      console.log(e);
    }
  }

  saveJsonToStorage(key: string, value: any) {
    try {
      return AsyncStorage.setItem(key, JSON.stringify(value));
    } catch (e) {
      console.log(e);
    }
  }

  loadAll = async (): Promise<StorageValues> => {
    try {
      let values = await AsyncStorage.multiGet([USER_STATE, SDK_CONFIG]);

      let user = this.createUser(values[0][1]);
      let sdkConfig = this.createSDKConfigurations(values[1][1]);

      return { user: user, sdkConfig: sdkConfig };
    } catch (e) {
      console.log(e);
      return { user: undefined, sdkConfig: undefined };
    }
  };

  createSDKConfigurations = (value: any): CustomerIoSDKConfig | undefined => {
    let json = value ? JSON.parse(value) : undefined;
    return json ? new CustomerIoSDKConfig(json) : undefined;
  };
  saveSDKConfigurations = async (config: CustomerIoSDKConfig) =>
    this.saveJsonToStorage(SDK_CONFIG, config);

  createUser = (value: any): User | undefined => {
    let json = value ? JSON.parse(value) : undefined;
    return json ? new User(json.email, json) : undefined;
  };
  saveUser = async (user: User) => this.saveJsonToStorage(USER_STATE, user);
  clearUser = async () => this.removeFromStorage(USER_STATE);
}
