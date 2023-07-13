import AsyncStorage from '@react-native-async-storage/async-storage';
import { SDK_CONFIG, USER_STATE } from '../constants/StorageConstants';
import User from '../data/models/user';
import CustomerIoSDKConfig from '../data/sdk/CustomerIoSDKConfig';

export default class StorageService {
  async loadFromStorage(key) {
    try {
      return await AsyncStorage.getItem(key);
    } catch (e) {
      console.log(e);
      return null;
    }
  }

  removeFromStorage(key, value) {
    try {
      return AsyncStorage.removeItem(key);
    } catch (e) {
      console.log(e);
      return null;
    }
  }

  saveJsonToStorage(key, value) {
    try {
      return AsyncStorage.setItem(key, JSON.stringify(value));
    } catch (e) {
      console.log(e);
      return null;
    }
  }

  loadAll = async () => {
    try {
      let values = await AsyncStorage.multiGet([USER_STATE, SDK_CONFIG]);

      let user = this.createUser(values[USER_STATE]);
      let sdkConfig = this.createSDKConfigurations(values[SDK_CONFIG]);

      return { user: user, sdkConfig: sdkConfig };
    } catch (e) {
      console.log(e);
      return null;
    }
  };

  createSDKConfigurations = (value) => {
    let json = value ? JSON.parse(value) : null;
    return json ? new CustomerIoSDKConfig(json) : null;
  };
  loadSDKConfigurations = async () =>
    this.createSDKConfigurations(await this.loadFromStorage(SDK_CONFIG));
  saveSDKConfigurations = async (config) =>
    this.saveJsonToStorage(SDK_CONFIG, config);

  createUser = (value) => {
    let json = value ? JSON.parse(value) : null;
    return json ? new User(json.email, json) : null;
  };
  loadUser = async () =>
    this.createUser(await this.loadFromStorage(USER_STATE));
  saveUser = async (user) => this.saveJsonToStorage(USER_STATE, user);
  clearUser = async () => this.saveJsonToStorage(USER_STATE, null);
}
