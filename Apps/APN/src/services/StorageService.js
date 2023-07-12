import AsyncStorage from '@react-native-async-storage/async-storage';
import { SDK_CONFIG, USER_STATE } from '../constants/StorageConstants';
import User from '../data/models/user';
import CustomerIoSDKConfig from '../data/sdk/CustomerIoSDKConfig';

export default class StorageService {
  async loadFromStorage(key) {
    try {
      const value = await AsyncStorage.getItem(key);
      return value ? JSON.parse(value) : null;
    } catch (e) {
      console.log(e);
    }
  }

  removeFromStorage(key, value) {
    try {
      return AsyncStorage.removeItem(key);
    } catch (e) {
      console.log(e);
    }
  }

  saveToStorage(key, value) {
    try {
      return AsyncStorage.setItem(key, JSON.stringify(value));
    } catch (e) {
      console.log(e);
    }
  }

  loadSDKConfigurations = async () => {
    let config = await this.loadFromStorage(SDK_CONFIG);
    return config ? new CustomerIoSDKConfig(config) : null;
  };
  saveSDKConfigurations = async (config) =>
    this.saveToStorage(SDK_CONFIG, config);

  loadUser = async () => {
    let user = await this.loadFromStorage(USER_STATE);
    return user ? new User(user.email, user) : null;
  };
  saveUser = async (user) => this.saveToStorage(USER_STATE, user);
  clearUser = async () => this.saveToStorage(USER_STATE, null);
}
