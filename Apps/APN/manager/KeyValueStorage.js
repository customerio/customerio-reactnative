import AsyncStorage from '@react-native-async-storage/async-storage';
import Constants from './../util/StorageConstants';

class CioKeyValueStorage {
  async saveToStorage(key, value) {
    try {
      await AsyncStorage.setItem(key, value);
    } catch (e) {
      console.log(e);
    }
  }

  async getFromStorage(key) {
    try {
      const value = await AsyncStorage.getItem(key);
      return value;
    } catch (e) {
      console.log(e);
    }
  }

  // Tracking URL
  async saveTrackingUrl(value) {
    this.saveToStorage(Constants.TRACKING_URL_KEY, value);
  }

  async getTrackingUrl() {
    return this.getFromStorage(Constants.TRACKING_URL_KEY);
  }

  // BGQ-DELAY
  async saveBGQSecondsDelay(value) {
    this.saveToStorage(Constants.BGQ_SECONDS_DELAY, value);
  }

  async getBGQSecondsDelay() {
    return this.getFromStorage(Constants.BGQ_SECONDS_DELAY);
  }

  // BGQ-MinTasks
  async saveBGQMinTasksInQueue(value) {
    this.saveToStorage(Constants.BGQ_MIN_TASKS_IN_QUEUE, value);
  }

  async getBGQMinTasksInQueue() {
    return this.getFromStorage(Constants.BGQ_MIN_TASKS_IN_QUEUE);
  }

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

  // Track Screen
  async saveScreenTrack(value) {
    this.saveToStorage(Constants.SCREEN_TRACK_STATUS, JSON.stringify(value));
  }

  async getScreenTrack() {
    return this.getFromStorage(Constants.SCREEN_TRACK_STATUS);
  }

  // Track device attributes
  async saveDeviceAttributesTrack(value) {
    this.saveToStorage(
      Constants.TRACK_DEVICE_ATTRIBUTES_STATUS,
      JSON.stringify(value)
    );
  }

  async getDeviceAttributesTrack() {
    return this.getFromStorage(Constants.TRACK_DEVICE_ATTRIBUTES_STATUS);
  }

  // Debug mode
  async saveDebugModeConfig(value) {
    this.saveToStorage(Constants.DEBUG_MODE_STATUS, JSON.stringify(value));
  }

  async getDebugModeConfig() {
    return this.getFromStorage(Constants.DEBUG_MODE_STATUS);
  }

  // Push notifications
  async saveIsPushEnabledConfig(value) {
    this.saveToStorage(Constants.PUSH_ENABLED_STATUS, JSON.stringify(value));
  }

  async getIsPushEnabledConfig() {
    return this.getFromStorage(Constants.PUSH_ENABLED_STATUS);
  }
}

export default CioKeyValueStorage;
