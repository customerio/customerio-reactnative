import { NativeModules, Platform } from 'react-native';
import { CioLogLevel, type CioConfig } from './cio-config';
import {type IdentifyParams } from './cio-params';
// TODO: Import the CustomerIOInAppMessaging and CustomerIOPushMessaging classes from their respective files
// when they are implemented.
// import { CustomerIOInAppMessaging } from './customerio-inapp';
// import { CustomerIOPushMessaging } from './customerio-push';
import { NativeLoggerListener } from './native-logger-listener';

const LINKING_ERROR =
  `The package 'customerio-reactnative' doesn't seem to be linked. Make sure: ` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const NativeCustomerIO = NativeModules.NativeCustomerIO
  ? NativeModules.NativeCustomerIO
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

export class CustomerIO {
  private static initialized = false;

  static readonly initialize = async (config: CioConfig) => {
    if (config.logLevel && config.logLevel !== CioLogLevel.None) {
      NativeLoggerListener.initialize();
    }
    let logLevel = config.logLevel?.valueOf() ?? CioLogLevel.Error.valueOf();
    NativeCustomerIO.initialize(config, logLevel);
    CustomerIO.initialized = true;
  };

  static readonly identify = async ({ id, traits }: IdentifyParams = {}) => {
    CustomerIO.assrtInitialized();
    if (!id && !traits) {
      throw new Error('You must provide an id or traits to identify');
    }
    return NativeCustomerIO.identify(id, traits);
  };

  static readonly clearIdentify = async () => {
    return NativeCustomerIO.clearIdentify();
  };

  static readonly track = async (
    name: string,
    properties?: Record<string, any>
  ) => {
    CustomerIO.assrtInitialized();
    if (!name) {
      throw new Error('You must provide a name to track');
    }
    return NativeCustomerIO.track(name, properties);
  };

  static readonly screen = async (
    title: string,
    properties?: Record<string, any>
  ) => {
    CustomerIO.assrtInitialized();
    if (!title) {
      throw new Error('You must provide a name to screen');
    }
    return NativeCustomerIO.screen(title, properties);
  };

  static readonly setProfileAttributes = async (
    attributes: Record<string, any>
  ) => {
    return NativeCustomerIO.setProfileAttributes(attributes);
  };

  static readonly setDeviceAttributes = async (
    attributes: Record<string, any>
  ) => {
    return NativeCustomerIO.setDeviceAttributes(attributes);
  };
  
  static readonly registerDeviceToken = async (
    token: string
  ) => {
    if (token === null || token === undefined) {
      throw new Error('You must provide a valid token to register device token.');
    }
    NativeCustomerIO.registerDeviceToken(token);
  };

  static readonly deleteDeviceToken = async () => {
    NativeCustomerIO.deleteDeviceToken();
  };

  static readonly isInitialized = () => CustomerIO.initialized;

  // TODO: Update when implemented.
  // static readonly inAppMessaging = new CustomerIOInAppMessaging();
  // static readonly pushMessaging = new CustomerIOPushMessaging();

  private static readonly assrtInitialized = () => {
    if (!CustomerIO.initialized) {
      throw new Error('CustomerIO must be initialized before use');
    }
  };
}