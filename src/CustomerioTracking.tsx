import { NativeModules, Platform } from 'react-native';
import {
  CustomerioConfig,
  CustomerIOEnv,
  PackageConfig,
} from './CustomerioConfig';
import { Region } from './CustomerioEnum';
var pjson = require("customerio-reactnative/package.json");

const LINKING_ERROR =
  `The package 'customerio-reactnative' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

/**
 * Get CustomerioReactnative native module
 */
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

class CustomerIO {
  /**
   * To initialize the package using workspace credentials
   * such as siteId, APIKey and region as optional.
   *
   * @param env use CustomerIOEnv class to set environment variables such as siteId, apiKey, region, org id
   * @param config set config for the package eg trackApiUrl etc
   * @returns
   */
  static initialize(
    env: CustomerIOEnv,
    config: CustomerioConfig = new CustomerioConfig()
  ) {
    let pversion = pjson.version ?? '';
    let expoVersion = pjson.expoVersion ?? '';

    const packageConfig = new PackageConfig();
    packageConfig.source = 'ReactNative';
    packageConfig.version = pversion;
    if (expoVersion != '') {
      packageConfig.source = 'Expo';
      packageConfig.version = expoVersion;
    }

    return CustomerioReactnative.initialize(env, config, packageConfig);
  }

  /**
   * Identify a person using a unique identifier, eg. email id.
   * Note that you can identify only 1 profile at a time. In case, multiple
   * identifiers are attempted to be identified, then the last identified profile
   * will be removed automatically.
   *
   * @param identifier unique identifier for a profile
   * @param body (Optional) data to identify a profile
   */
  static identify(identifier: string, body: Object) {
    CustomerioReactnative.identify(identifier, body);
  }

  /**
   * Call this function to stop identifying a person.
   *
   * If a profile exists, clearIdentify will stop identifying the profile.
   * If no profile exists, request to clearIdentify will be ignored.
   */
  static clearIdentify() {
    CustomerioReactnative.clearIdentify();
  }

  /**
   * To track user events like loggedIn, addedItemToCart etc.
   * You may also track events with additional yet optional data.
   *
   * @param name event name to be tracked
   * @param data (Optional) data to be sent with event
   */
  static track(name: string, data: Object) {
    CustomerioReactnative.track(name, data);
  }

  /**
   * Use this function to send custom device attributes
   * such as app preferences, timezone etc
   *
   * @param data device attributes data
   */
  static setDeviceAttributes(data: Object) {
    CustomerioReactnative.setDeviceAttributes(data);
  }

  /**
   * Set custom user profile information such as user preference, specific
   * user actions etc
   *
   * @param data additional attributes for a user profile
   */
  static setProfileAttributes(data: Object) {
    CustomerioReactnative.setProfileAttributes(data);
  }

  /**
   * Track screen events to record the screens a user visits
   *
   * @param name name of the screen user visited
   * @param data (Optional) any additional data to be sent
   */
  static screen(name: string, data: Object) {
    CustomerioReactnative.screen(name, data);
  }
}

export { CustomerIO, Region };
