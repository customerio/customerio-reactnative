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

      let user = this.createUser(values[0][1]);
      let sdkConfig = this.createSDKConfigurations(values[1][1]);

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
  saveSDKConfigurations = async (config) =>
    this.saveJsonToStorage(SDK_CONFIG, config);

  createUser = (value) => {
    let json = value ? JSON.parse(value) : null;
    return json ? new User(json.email, json) : null;
  };
  saveUser = async (user) => this.saveJsonToStorage(USER_STATE, user);
  clearUser = async () => this.saveJsonToStorage(USER_STATE, null);
}
