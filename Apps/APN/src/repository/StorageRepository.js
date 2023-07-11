import AsyncStorage from '@react-native-async-storage/async-storage';
import SDKConfigurations from '../sdk/SDKConfigurations';
import { StorageConstants } from '../util/Constants';
import User from '../src/data/models/user';

export default class StoreManager {
  saveToStorage(key, value) {
    try {
      return AsyncStorage.setItem(key, JSON.stringify(value));
    } catch (e) {
      console.log(e);
    }
  }

  async loadFromStorage(key) {
    try {
      const value = await AsyncStorage.getItem(key);
      return value ? JSON.parse(value) : null;
    } catch (e) {
      console.log(e);
    }
  }

  loadSDKConfigurations = async () => {
    let config = await this.loadFromStorage(StorageConstants.SDK_CONFIG);
    return config ? new SDKConfigurations(config) : null;
  };
  saveSDKConfigurations = async (config) =>
    this.saveToStorage(StorageConstants.SDK_CONFIG, config);

  loadUser = async () => {
    let user = await this.loadFromStorage(StorageConstants.USER_STATE);
    return user ? new User(user.email, user) : null;
  };
  saveUser = async (user) =>
    this.saveToStorage(StorageConstants.USER_STATE, user);
}
