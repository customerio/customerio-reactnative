import { type TurboModule } from 'react-native';
import { CustomerIOInAppMessaging } from './customerio-inapp';
import { CustomerIOPushMessaging } from './customerio-push';
import { NativeLoggerListener } from './native-logger-listener';
import {
  default as NativeModule,
  type Spec as CodegenSpec,
} from './specs/modules/NativeCustomerIO';
import {
  CioLogLevel,
  type CioConfig,
  type CustomAttributes,
  type IdentifyParams,
} from './types';
import type { NativeSDKArgs } from './types/internal';
import { callNativeModule, ensureNativeModule } from './utils/native-bridge';
import { assert, validate } from './utils/param-validation';

const packageJson = require('customerio-reactnative/package.json');

// Ensures all methods defined in codegen spec are implemented by the public module
interface NativeSpec extends Omit<CodegenSpec, keyof TurboModule> {
  isInitialized(): boolean;
  inAppMessaging: CustomerIOInAppMessaging;
  pushMessaging: CustomerIOPushMessaging;
}

// Track whether CustomerIO SDK has been initialized to prevent usage before setup
let _initialized = false;

// Reference to the native CustomerIO Data Pipelines module for SDK operations
const nativeModule = ensureNativeModule(NativeModule);

// Wrapper function that ensures SDK is initialized before calling native methods
const withNativeModule = <R>(fn: (native: CodegenSpec) => R): R => {
  if (!_initialized) {
    throw new Error(
      'CustomerIO SDK must be initialized before calling any methods. Please call CustomerIO.initialize() first.'
    );
  }
  return callNativeModule(nativeModule, fn);
};

export const CustomerIO = {
  /** Initialize the CustomerIO SDK with given configuration. */
  initialize: async (config: CioConfig) => {
    assert.config(config);

    if (config.logLevel && config.logLevel !== CioLogLevel.None) {
      await NativeLoggerListener.initialize();
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
  },

  /** Identify a user to start tracking their activity. Requires userId, traits, or both. */
  identify: ({ userId, traits }: IdentifyParams) => {
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

    return withNativeModule((native) =>
      native.identify({ userId, traits: normalizedTraits })
    );
  },

  /** Clear current user identification and stop tracking. */
  clearIdentify: () => {
    return withNativeModule((native) => native.clearIdentify());
  },

  /** Track an event with optional properties. */
  track: (name: string, properties?: CustomAttributes) => {
    assert.string(name, 'name', { usage: 'Track Event' });
    const normalizedProps = assert.attributes(properties, 'properties', {
      usage: 'Track Event',
      optional: true,
    });

    return withNativeModule((native) => native.track(name, normalizedProps));
  },

  /** Track a screen view event with optional properties. */
  screen: (title: string, properties?: CustomAttributes) => {
    assert.string(title, 'title', { usage: 'Screen' });
    const normalizedProps = assert.attributes(properties, 'properties', {
      usage: 'Screen',
      optional: true,
    });

    return withNativeModule((native) => native.screen(title, normalizedProps));
  },

  /** Set or update attributes for the currently identified user profile. */
  setProfileAttributes: (attributes: CustomAttributes) => {
    const normalizedAttrs = assert.attributes(attributes, 'attributes', {
      usage: 'Profile',
    }) as CustomAttributes;

    return withNativeModule((native) =>
      native.setProfileAttributes(normalizedAttrs)
    );
  },

  /** Set attributes for the current device. */
  setDeviceAttributes: (attributes: CustomAttributes) => {
    const normalizedAttrs = assert.attributes(attributes, 'attributes', {
      usage: 'Device',
    }) as CustomAttributes;

    return withNativeModule((native) =>
      native.setDeviceAttributes(normalizedAttrs)
    );
  },

  /** Register a device token for push notifications. */
  registerDeviceToken: (token: string) => {
    assert.string(token, 'token', { usage: 'Device' });

    withNativeModule((native) => native.registerDeviceToken(token));
  },

  /** Remove the current device token to stop receiving push notifications. */
  deleteDeviceToken: () => {
    withNativeModule((native) => native.deleteDeviceToken());
  },

  /** Check if the CustomerIO SDK has been initialized. */
  isInitialized() {
    return _initialized;
  },

  inAppMessaging: new CustomerIOInAppMessaging(),
  pushMessaging: new CustomerIOPushMessaging(),
} satisfies NativeSpec;
