import { CustomerIOInAppMessaging } from './customerio-inapp';
import { CustomerIOPushMessaging } from './customerio-push';
import { NativeLoggerListener } from './native-logger-listener';
import {
  default as NativeModule,
  type Spec as CodegenSpec,
} from './specs/modules/NativeCustomerIO';
import {
  CioLogLevel,
  MetricEvent,
  type CioConfig,
  type CustomAttributes,
  type IdentifyParams,
} from './types';
import type { NativeSDKArgs } from './types/internal';
import { callNativeModule, ensureNativeModule } from './utils/native-bridge';
import { assert, validate } from './utils/param-validation';

const packageJson = require('customerio-reactnative/package.json');

// Track whether CustomerIO SDK has been initialized to prevent usage before setup
let _initialized = false;

// Reference to the native CustomerIO Data Pipelines module for SDK operations
const nativeModule = ensureNativeModule(NativeModule);

// Wrapper function that ensures SDK is initialized before calling native methods
const withNativeModule = <R>(fn: (native: CodegenSpec) => R): R => {
  return callNativeModule(nativeModule, fn);
};

/** @public */
export class CustomerIO {
  /** Initialize the CustomerIO SDK with given configuration. */
  static readonly initialize = async (config: CioConfig) => {
    assert.config(config);

    if (config.logLevel && config.logLevel !== CioLogLevel.None) {
      NativeLoggerListener.initialize();
    }

    const expoVersion = packageJson.expoVersion ?? '';
    const args: NativeSDKArgs = {
      packageSource: expoVersion ? 'Expo' : 'ReactNative',
      packageVersion: expoVersion || packageJson.version || '',
    };

    return callNativeModule(NativeModule, (native) => {
      let result = native.initialize(config, args);
      _initialized = true;
      return result;
    });
  };

  /** Identify a user to start tracking their activity. Requires userId, traits, or both. */
  static readonly identify = async ({
    userId,
    traits,
  }: IdentifyParams = {}) => {
    if (validate.isUndefined(userId) && validate.isUndefined(traits)) {
      throw new Error('You must provide either userId or traits to identify');
    }

    assert.string(userId, 'userId', {
      allowEmpty: false,
      usage: 'Identify',
      optional: true,
    });
    const normalizedTraits = assert.attributes(traits, 'traits', {
      usage: 'Identify',
      optional: true,
    });

    return withNativeModule<any>((native) =>
      native.identify({ userId, traits: normalizedTraits })
    );
  };

  /** Clear current user identification and stop tracking. */
  static readonly clearIdentify = async () => {
    return withNativeModule<any>((native) => native.clearIdentify());
  };

  /** Track an event with optional properties. */
  static readonly track = async (
    name: string,
    properties?: Record<string, any>
  ) => {
    assert.string(name, 'name', { usage: 'Track Event' });
    const normalizedProps = assert.attributes(properties, 'properties', {
      usage: 'Track Event',
      optional: true,
    });

    return withNativeModule<any>((native) =>
      native.track(name, normalizedProps)
    );
  };

  /** Track a screen view event with optional properties. */
  static readonly screen = async (
    title: string,
    properties?: Record<string, any>
  ) => {
    assert.string(title, 'title', { usage: 'Screen' });
    const normalizedProps = assert.attributes(properties, 'properties', {
      usage: 'Screen',
      optional: true,
    });

    return withNativeModule<any>((native) =>
      native.screen(title, normalizedProps)
    );
  };

  /** Set or update attributes for the currently identified user profile. */
  static readonly setProfileAttributes = async (
    attributes: Record<string, any>
  ) => {
    const normalizedAttrs = assert.attributes(attributes, 'attributes', {
      usage: 'Profile',
    }) as CustomAttributes;

    return withNativeModule<any>((native) =>
      native.setProfileAttributes(normalizedAttrs)
    );
  };

  /** Set attributes for the current device. */
  static readonly setDeviceAttributes = async (
    attributes: Record<string, any>
  ) => {
    const normalizedAttrs = assert.attributes(attributes, 'attributes', {
      usage: 'Device',
    }) as CustomAttributes;

    return withNativeModule<any>((native) =>
      native.setDeviceAttributes(normalizedAttrs)
    );
  };

  /** Register a device token for push notifications. */
  static readonly registerDeviceToken = async (token: string) => {
    assert.string(token, 'token', { usage: 'Device' });

    return withNativeModule((native) => native.registerDeviceToken(token));
  };

  /** Remove the current device token to stop receiving push notifications. */
  static readonly deleteDeviceToken = async () => {
    return withNativeModule((native) => native.deleteDeviceToken());
  };

  /** Track push notification metrics for delivered, opened, or converted events. */
  static readonly trackMetric = async ({
    deliveryID,
    deviceToken,
    event,
  }: {
    deliveryID: string;
    deviceToken: string;
    event: MetricEvent;
  }) => {
    assert.string(deliveryID, 'deliveryID', { usage: 'Track Metric' });
    assert.string(deviceToken, 'deviceToken', { usage: 'Track Metric' });

    return withNativeModule((native) =>
      native.trackMetric(deliveryID, deviceToken, event)
    );
  };

  /**
   * Check if the CustomerIO SDK has been initialized.
   * @deprecated This method will be removed in a future version. If you need this functionality, please contact us.
   */
  static readonly isInitialized = () => _initialized;

  static readonly inAppMessaging = new CustomerIOInAppMessaging();
  static readonly pushMessaging = new CustomerIOPushMessaging();
}

// Initialize native logger when this module loads to ensure it's always available.
// Since customerio-cdp.ts is the main SDK entry point and always imported,
// this guarantees logger initialization even when native-logger-listener.ts
// isn't directly accessed, also supporting auto-initialization in Expo apps.
NativeLoggerListener.initNativeLogger();
