import { CustomerIOGeofence } from './customerio-geofence';
import { CustomerIOInAppMessaging } from './customerio-inapp';
import { CustomerIOLiveActivities } from './customerio-liveactivities';
import { CustomerIOLocation } from './customerio-location';
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
let deepLinkHandlerSubscription: DeepLinkHandlerSubscription | undefined;

/**
 * Handles a Customer.io deep-link destination delivered from iOS.
 * @public
 */
export type DeepLinkHandler = (url: string) => boolean | Promise<boolean>;

/**
 * Removes a Customer.io deep-link handler.
 * @public
 */
export interface DeepLinkHandlerSubscription {
  /** Stop routing Customer.io deep links through this handler. */
  remove(): void;
}

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

    const promise = callNativeModule(NativeModule, (native) =>
      native.initialize(config, args)
    );
    return promise.then(() => {
      _initialized = true;
    });
  };

  /**
   * Signal that the app's React Native Linking listener is ready to receive Customer.io URLs.
   *
   * This is only needed by UIScene hosts that initialize Customer.io natively, such as Expo
   * config-plugin auto-initialization. Call it after registering the Linking listener.
   */
  static readonly setDeepLinkRoutingReady = () => {
    return withNativeModule<void>((native) => native.setDeepLinkRoutingReady());
  };

  /**
   * Register an acknowledged deep-link handler for an iOS UIScene host.
   *
   * This API only handles Customer.io destinations delivered through an iOS UIScene lifecycle.
   * In a native React Native scene host, pair this with
   * `NativeCustomerIO.configureAcknowledgedSceneDeepLinkRouting()` in the SceneDelegate. Register
   * this before `initialize` when possible. Return `true` after routing a URL. Returning `false`,
   * throwing, or rejecting lets the native SDK try the host AppDelegate, then React Native Linking
   * for a host-owned custom scheme or the system for other URLs. Cold URLs are buffered until this
   * handler is registered, subject to the native timeout. After delivery, the handler has ten
   * seconds to settle. Once that timeout runs the native fallback, a late handler cannot cancel it
   * and may cause a second navigation if it also routes the URL.
   */
  static readonly setDeepLinkHandler = (
    handler: DeepLinkHandler
  ): DeepLinkHandlerSubscription => {
    if (typeof handler !== 'function') {
      throw new Error('[CustomerIO] "handler" must be a function.');
    }

    // Native unregister is tokenless and removes the current native handler. Remove the old
    // subscription first so its cleanup cannot unregister the replacement.
    deepLinkHandlerSubscription?.remove();

    return withNativeModule<DeepLinkHandlerSubscription>((native) => {
      const nativeSubscription = native.onDeepLinkReceived(async (data) => {
        const event = data as { id?: unknown; url?: unknown };
        if (typeof event.id !== 'string' || typeof event.url !== 'string') {
          NativeLoggerListener.warn(
            'Received an invalid native deep-link event.'
          );
          return;
        }

        let handled = false;
        try {
          handled = (await handler(event.url)) === true;
        } catch (error) {
          NativeLoggerListener.warn('Deep-link handler failed:', error);
        }

        try {
          native.acknowledgeDeepLink(event.id, handled);
        } catch (error) {
          NativeLoggerListener.warn(
            'Failed to acknowledge a deep-link result:',
            error
          );
        }
      });

      let removed = false;
      const subscription: DeepLinkHandlerSubscription = {
        remove: () => {
          if (removed) {
            return;
          }
          removed = true;
          try {
            native.unregisterDeepLinkHandler();
          } finally {
            nativeSubscription.remove();
            if (deepLinkHandlerSubscription === subscription) {
              deepLinkHandlerSubscription = undefined;
            }
          }
        },
      };

      try {
        native.registerDeepLinkHandler();
      } catch (error) {
        try {
          native.unregisterDeepLinkHandler();
        } catch {
          // Preserve the registration error; the native timeout still owns pending URLs.
        }
        nativeSubscription.remove();
        throw error;
      }

      deepLinkHandlerSubscription = subscription;
      return subscription;
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
    assert.string(event, 'event', { usage: 'Track Metric' });

    return withNativeModule((native) =>
      native.trackMetric(deliveryID, deviceToken, event)
    );
  };

  /**
   * Check if the CustomerIO SDK has been initialized.
   * @deprecated This method will be removed in a future version. If you need this functionality, please contact us.
   */
  static readonly isInitialized = () => _initialized;

  static readonly geofence = new CustomerIOGeofence();
  static readonly inAppMessaging = new CustomerIOInAppMessaging();
  static readonly liveActivities = new CustomerIOLiveActivities();
  static readonly location = new CustomerIOLocation();
  static readonly pushMessaging = new CustomerIOPushMessaging();
}

// Initialize native logger when this module loads to ensure it's always available.
// Since customerio-cdp.ts is the main SDK entry point and always imported,
// this guarantees logger initialization even when native-logger-listener.ts
// isn't directly accessed, also supporting auto-initialization in Expo apps.
NativeLoggerListener.initNativeLogger();
