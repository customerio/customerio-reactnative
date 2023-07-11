import AsyncStorage from '@react-native-async-storage/async-storage';
import { StorageConstants } from '../util/Constants';
import Constants from './../util/StorageConstants';

class CioKeyValueStorage {
  async saveToStorage(key, value) {
    try {
      await AsyncStorage.setItem(key, JSON.stringify(value));
    } catch (e) {
      console.log(e);
    }
  }

  async getFromStorage(key) {
    try {
      const value = await AsyncStorage.getItem(key);
      return value ? JSON.parse(value) : null;
    } catch (e) {
      console.log(e);
    }
  }

  getSiteId = () => this.getFromStorage(StorageConstants.SITE_ID);
  saveSiteId = (value) => this.saveToStorage(StorageConstants.SITE_ID, value);

  getApiKey = () => this.getFromStorage(StorageConstants.API_KEY);
  saveApiKey = (value) => this.saveToStorage(StorageConstants.API_KEY, value);

  getTrackingUrl = () => this.getFromStorage(StorageConstants.TRACKING_URL);
  saveTrackingUrl = (value) =>
    this.saveToStorage(StorageConstants.TRACKING_URL, value);

  getBQSecondsDelay = () =>
    this.getFromStorage(StorageConstants.BQ_SECONDS_DELAY);
  saveBQSecondsDelay = (value) =>
    this.saveToStorage(StorageConstants.BQ_SECONDS_DELAY, value);

  getBQMinTasks = () => this.getFromStorage(StorageConstants.BQ_MIN_TASKS);
  saveBQMinTasks = (value) =>
    this.saveToStorage(StorageConstants.BQ_MIN_TASKS, value);

  getTrackScreens = () => this.getFromStorage(StorageConstants.TRACK_SCREENS);
  saveTrackScreens = (value) =>
    this.saveToStorage(StorageConstants.TRACK_SCREENS, value);

  getTrackDeviceAttributes = () =>
    this.getFromStorage(StorageConstants.TRACK_DEVICE_ATTRIBUTES);
  saveTrackDeviceAttributes = (value) =>
    this.saveToStorage(StorageConstants.TRACK_DEVICE_ATTRIBUTES, value);

  getDebugMode = () => this.getFromStorage(StorageConstants.DEBUG_MODE);
  saveDebugMode = (value) =>
    this.saveToStorage(StorageConstants.DEBUG_MODE, value);

  // Login Status
  async saveLoginStatus(value) {
    this.saveToStorage(Constants.LOGIN_STATUS, JSON.stringify(value));
  }

  async getLoginStatus(value) {
    return this.getFromStorage(Constants.LOGIN_STATUS);
  }

  // Login details
  async saveLoginDetail(value) {
    this.saveToStorage(Constants.LOGIN_DETAIL, JSON.stringify(value));
  }

  async getLoginDetail(value) {
    return this.getFromStorage(Constants.LOGIN_DETAIL);
  }
}

export default CioKeyValueStorage;
