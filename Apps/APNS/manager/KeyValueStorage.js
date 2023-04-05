import AsyncStorage from '@react-native-async-storage/async-storage';


class CioKeyValueStorage {

  // Tracking URL
  async saveTrackingUrl(value) {
    try {
      await AsyncStorage.setItem('tracking_url', value)
    } catch (e) {
      console.log(e)
    }
  }

  async getTrackingUrl(){
    try {
      const value = await AsyncStorage.getItem('tracking_url')
      return value
    } catch(e) {
      console.log(e)
    }
  }

  // BG-Q
  async saveBGQSecondsDelay(value) {
    try {
      await AsyncStorage.setItem('bgQSecondsDelay', value)
    } catch (e) {
      console.log(e)
    }
  }

  async getBGQSecondsDelay(){
    try {
      const value = await AsyncStorage.getItem('bgQSecondsDelay')
      return value
    } catch(e) {
      console.log(e)
    }
  }

  async saveBGQMinTasksInQueue(value) {
    try {
      await AsyncStorage.setItem('bgQMinTasksInQueue', value)
    } catch (e) {
      console.log(e)
    }
  }

  async getBGQMinTasksInQueue(){
    try {
      const value = await AsyncStorage.getItem('bgQMinTasksInQueue')
      return value
    } catch(e) {
      console.log(e)
    }
  }

  // Login Status
  async saveLoginStatus(value) {
    try {
      await AsyncStorage.setItem('loginStatus', JSON.stringify(value))
    } catch (e) {
      console.log(e)
    }
  }

  async getLoginStatus(value) {
    try {
      const value = await AsyncStorage.getItem('loginStatus')
      return value
    } catch(e) {
      console.log(e)
    }
  }

  // Login details
  async saveLoginDetail(value) {
    try {
      await AsyncStorage.setItem('loginDetail', JSON.stringify(value))
    } catch (e) {
      console.log(e)
    }
  }

  async getLoginDetail(value) {
    try {
      const value = await AsyncStorage.getItem('loginDetail')
      return value
    } catch(e) {
      console.log(e)
    }
  } 

  // Track Screen
  async saveScreenTrack(value) {
    try {
      await AsyncStorage.setItem('screen_track', JSON.stringify(value))
    } catch (e) {
      console.log(e)
    }
  }

  async getScreenTrack(){
    try {
      const value = await AsyncStorage.getItem('screen_track')
      return value
    } catch(e) {
      console.log(e)
    }
  }

  // Track device attributes
  async saveDeviceAttributesTrack(value) {
    try {
      await AsyncStorage.setItem('device_attributes_track', JSON.stringify(value))
    } catch (e) {
      console.log(e)
    }
  }

  async getDeviceAttributesTrack(){
    try {
      const value = await AsyncStorage.getItem('device_attributes_track')
      return value
    } catch(e) {
      console.log(e)
    }
  }

// Debug mode
async saveDebugModeConfig(value) {
  try {
    await AsyncStorage.setItem('debug_mode', JSON.stringify(value))
  } catch (e) {
    console.log(e)
  }
}

async getDebugModeConfig(){
  try {
    const value = await AsyncStorage.getItem('debug_mode')
    return value
  } catch(e) {
    console.log(e)
  }
}

  // Push notifications
  async saveIsPushEnabledConfig(value) {
    try {
      await AsyncStorage.setItem('push_enabled', JSON.stringify(value))
    } catch (e) {
      console.log(e)
    }
  }
  
  async getIsPushEnabledConfig(){
    try {
      const value = await AsyncStorage.getItem('push_enabled')
      return value
    } catch(e) {
      console.log(e)
    }
  }
}


export default CioKeyValueStorage;