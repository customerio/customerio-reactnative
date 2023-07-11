import AsyncStorage from '@react-native-async-storage/async-storage';
import { SDK_CONFIG, USER_STATE } from '../constants/StorageConstants';
import CustomerIoSDKConfig from '../data/sdk/CustomerIoSDKConfig';
import User from '../data/models/user';

export default class StorageService {
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
}
