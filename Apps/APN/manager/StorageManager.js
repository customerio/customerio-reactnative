import AsyncStorage from '@react-native-async-storage/async-storage';
import SDKConfigurations from '../sdk/SDKConfigurations';
import { StorageConstants } from '../util/Constants';

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

  loadSDKConfigurations = async () =>
    new SDKConfigurations(
      await this.loadFromStorage(StorageConstants.SDK_CONFIG)
    );
  saveSDKConfigurations = async (config) =>
    this.saveToStorage(StorageConstants.SDK_CONFIG, config);
}
