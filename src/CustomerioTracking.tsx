import { NativeModules, Platform } from 'react-native';
import {
  CustomerioConfig,
  CustomerIOEnv,
  PackageConfig,
} from './CustomerioConfig';
import { Region } from './CustomerioEnum';
import { CustomerIOInAppMessaging } from './CustomerIOInAppMessaging';
import { CustomerIOPushMessaging } from './CustomerIOPushMessaging';
import type { PushPermissionStatus, PushPermissionOptions } from './types';
import {
  createClient,
  SegmentClient,
  UserTraits,
  JsonMap,
} from '@segment/analytics-react-native/src';

var pjson = require('customerio-reactnative/package.json');

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
  static segmentClient: SegmentClient; // global variable declaration
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
    if (expoVersion !== '') {
      packageConfig.source = 'Expo';
      packageConfig.version = expoVersion;
    }
    if (env.organizationId && env.organizationId !== '') {
      console.warn(
        '{organizationId} is deprecated and will be removed in future releases, please remove {organizationId} and enable in-app messaging using {CustomerioConfig.enableInApp}'
      );
      if (config.enableInApp === false) {
        config.enableInApp = true;
        console.warn(
          '{config.enableInApp} set to {true} because {organizationId} was added'
        );
      }
    }

    var writeKey = `${env.apiKey}:${env.apiKey}`; // For backward compatibility
    if (env.writeKey && env.writeKey !== '') {
      writeKey = env.writeKey;
    }
    // TODO: Match configurations CIO = SEGMENT
    this.segmentClient = createClient({
      writeKey: writeKey,
      debug: true,
      trackAppLifecycleEvents: true,
      autoAddCustomerIODestination: true,
    });
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
  static identify(identifier: string, body?: UserTraits) {
    this.segmentClient.identify(identifier, body);
  }

  /**
   * Call this function to stop identifying a person.
   *
   * If a profile exists, clearIdentify will stop identifying the profile.
   * If no profile exists, request to clearIdentify will be ignored.
   */
  static clearIdentify() {
    this.segmentClient.reset();
  }

  /**
   * To track user events like loggedIn, addedItemToCart etc.
   * You may also track events with additional yet optional data.
   *
   * @param name event name to be tracked
   * @param data (Optional) data to be sent with event
   */
  static track(name: string, data?: JsonMap) {
    this.segmentClient.track(name, data);
  }

  /**
   * Use this function to send custom device attributes
   * such as app preferences, timezone etc
   *
   * @param data device attributes data
   */
  static setDeviceAttributes(data: JsonMap) {
    this.segmentClient.registerDevice(data);
  }

  /**
   * Set custom user profile information such as user preference, specific
   * user actions etc
   *
   * @param data additional attributes for a user profile
   */
  static setProfileAttributes(data: UserTraits) {
    this.segmentClient.identify(undefined, data);
  }

  /**
   * Track screen events to record the screens a user visits
   *
   * @param name name of the screen user visited
   * @param data (Optional) any additional data to be sent
   */
  static screen(name: string, data?: JsonMap) {
    this.segmentClient.screen(name, data);
  }

  static inAppMessaging(): CustomerIOInAppMessaging {
    return new CustomerIOInAppMessaging();
  }

  static pushMessaging(): CustomerIOPushMessaging {
    return new CustomerIOPushMessaging();
  }

  /**
   * Register a device with respect to a profile.
   * If no profile is identified, no device will be registered.
   *
   * @param token device token (iOS/Android)
   */
  static registerDeviceToken(token: string) {
    if (token == null) {
      return;
    }
    this.segmentClient.registerDevice({ token: token });
  }

  static deleteDeviceToken() {
    this.segmentClient.deleteDevice();
  }

  /**
   * Request to show prompt for push notification permissions.
   * Prompt will only be shown if the current status is - not determined.
   * In other cases, this function will return current status of permission.
   * @param options
   * @returns Success & Failure promises
   */
  static async showPromptForPushNotifications(
    options?: PushPermissionOptions
  ): Promise<PushPermissionStatus> {
    let defaultOptions: PushPermissionOptions = {
      ios: {
        badge: true,
        sound: true,
      },
    };

    return CustomerioReactnative.showPromptForPushNotifications(
      options || defaultOptions
    );
  }

  /**
   * Get status of push permission for the app
   * @returns Promise with status of push permission as a string
   */
  static getPushPermissionStatus(): Promise<PushPermissionStatus> {
    return CustomerioReactnative.getPushPermissionStatus();
  }
}

export { CustomerIO, Region };
