import { NativeModules, Platform } from 'react-native';
import { CustomerioConfig } from './CustomerioConfig';

const LINKING_ERROR =
  `The package 'customerio-reactnative' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';
const CustomerioReactnative = NativeModules.CustomerioReactnative
  ? NativeModules.CustomerioReactnative
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );
    enum Region {
        US = "US",
        EU = "EU",
      }
class CustomerIO {
    static initialize(siteId: string, apiKey: string, region: Region = Region.US) {
      return CustomerioReactnative.initialize(siteId, apiKey, region)
    }

    static identify(identifier: string, body: Object) {
      CustomerioReactnative.identify(identifier, body)
    }

    static clearIdentify() {
      CustomerioReactnative.clearIdentify()
    }

    static track(name: string, data : Object) {
      CustomerioReactnative.track(name, data)
    }

    static setDeviceAttributes(data : Object) {
      CustomerioReactnative.setDeviceAttributes(data)
    }

    static config(data : CustomerioConfig = new CustomerioConfig()) {
      CustomerioReactnative.config(data)
    }

    static setProfileAttributes(data : Object) {
      CustomerioReactnative.setProfileAttributes(data)
    }

    static screen(name : string, data : Object) {
      CustomerioReactnative.screen(name, data)
    }
  }

  export {
    CustomerIO,
    Region
  }