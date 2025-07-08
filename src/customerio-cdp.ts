import { type TurboModule } from 'react-native';
import { CustomerIOInAppMessaging } from './customerio-inapp';
import { CustomerIOPushMessaging } from './customerio-push';
import { NativeLoggerListener } from './native-logger-listener';
import {
  CioLogLevel,
  default as NativeModule,
  type CioConfig,
  type Spec as CodegenSpec,
  type CustomAttributes,
  type IdentifyParams,
  type NativeSDKArgs,
} from './specs/modules/NativeCustomerIO';
import { callNativeModule, ensureNativeModule } from './utils/native-bridge';
import { assert } from './utils/param-validation';

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
  initialize: (config: CioConfig) => {
    assert.config(config);

    if (config.logLevel && config.logLevel !== CioLogLevel.None) {
      NativeLoggerListener.initialize();
    }

    const packageVersion = packageJson.version ?? '';
    const args: NativeSDKArgs = {
      packageSource: 'ReactNative',
      packageVersion: packageVersion,
    };

    const expoVersion = packageJson.expoVersion ?? '';
    if (expoVersion !== '') {
      args.packageSource = 'Expo';
      args.packageVersion = expoVersion;
    }

    return callNativeModule(NativeModule, (native) => {
      let result = native.initialize(config, args);
      _initialized = true;
      return result;
    });
  },

  identify: ({ userId, traits }: IdentifyParams) => {
    if (!userId && !traits) {
      throw new Error('You must provide either userId or traits to identify');
    }
    if (userId !== undefined) {
      assert.string(userId, 'userId', { allowEmpty: false, usage: 'Identify' });
    }
    if (traits !== undefined) {
      assert.record(traits, 'traits', { usage: 'Identify' });
    }

    return withNativeModule((native) => native.identify({ userId, traits }));
  },

  clearIdentify: () => {
    return withNativeModule((native) => native.clearIdentify());
  },

  track: (name: string, properties?: CustomAttributes) => {
    assert.string(name, 'name', { usage: 'Track Event' });

    return withNativeModule((native) => native.track(name, properties));
  },

  screen: (title: string, properties?: CustomAttributes) => {
    assert.string(title, 'title', { usage: 'Screen' });

    return withNativeModule((native) => native.screen(title, properties));
  },

  setProfileAttributes: (attributes: CustomAttributes) => {
    assert.record(attributes, 'attributes', { usage: 'Profile' });

    return withNativeModule((native) =>
      native.setProfileAttributes(attributes)
    );
  },

  setDeviceAttributes: (attributes: CustomAttributes) => {
    assert.record(attributes, 'attributes', { usage: 'Device' });

    return withNativeModule((native) => native.setDeviceAttributes(attributes));
  },

  registerDeviceToken: (token: string) => {
    assert.string(token, 'token', { usage: 'Device' });

    withNativeModule((native) => native.registerDeviceToken(token));
  },

  deleteDeviceToken: () => {
    withNativeModule((native) => native.deleteDeviceToken());
  },

  isInitialized() {
    return _initialized;
  },

  inAppMessaging: new CustomerIOInAppMessaging(),
  pushMessaging: new CustomerIOPushMessaging(),
} satisfies NativeSpec;
