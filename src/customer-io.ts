import { NativeModules, Platform } from 'react-native';
import { CioLogLevel, type CioConfig } from './cio-config';
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
    NativeCustomerIO.initialize(config, config.logLevel);
    CustomerIO.initialized = true;
  };

  static readonly identify = async (
    id?: string,
    traits?: Record<string, any>
  ) => {
    CustomerIO.assrtInitialized();
    if (!id && !traits) {
      throw new Error('You must provide an id or traits to identify');
    }
    return NativeCustomerIO.identify(id, traits);
  };

  static readonly clearIdentify = async () => {
    CustomerIO.assrtInitialized();
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
    category?: string,
    properties?: Record<string, any>
  ) => {
    CustomerIO.assrtInitialized();
    if (!title) {
      throw new Error('You must provide a name to screen');
    }
    return NativeCustomerIO.screen(title, category, properties);
  };

  static readonly setProfileAttributes = async (
    attributes: Record<string, any>
  ) => {
    CustomerIO.assrtInitialized();
    return NativeCustomerIO.setProfileAttributes(attributes);
  };

  static readonly setDeviceAttributes = async (
    attributes: Record<string, any>
  ) => {
    CustomerIO.assrtInitialized();
    return NativeCustomerIO.setDeviceAttributes(attributes);
  };

  static readonly isInitialized = () => CustomerIO.initialized;

  private static readonly assrtInitialized = () => {
    if (!CustomerIO.initialized) {
      throw new Error('CustomerIO must be initialized before use');
    }
  };
}
