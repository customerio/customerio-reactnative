import { NativeEventEmitter } from 'react-native';
import NativeCustomerIOLogging from './specs/modules/NativeCustomerIOLogging';
import { CioLogLevel } from './types';
import { callNativeModule, ensureNativeModule } from './utils/native-bridge';

// Reference to the native CustomerIO logging module for SDK operations
const nativeModule = ensureNativeModule(NativeCustomerIOLogging);

// Wrapper function that ensures SDK is initialized before calling native methods
const withNativeModule = <R>(
  fn: (native: typeof NativeCustomerIOLogging) => R
): R => {
  return callNativeModule(nativeModule, fn);
};

// Prefix for all CustomerIO log messages
const loggerPrefix = '[CIO] ';

// Shared architecture detection cache, default to true (new arch)
let isNewArchEnabledCache: boolean = true;
let isArchCacheInitialized: boolean = false;

// Detect and cache React Native architecture type
export const isNewArchEnabled = async (): Promise<boolean> => {
  if (!isArchCacheInitialized) {
    try {
      const result = await callNativeModule(nativeModule, (native) =>
        native.isNewArchEnabled()
      );
      isNewArchEnabledCache = result;
      isArchCacheInitialized = true;
    } catch (error) {
      console.warn(`${loggerPrefix} Failed to determine architecture.`, error);
      isArchCacheInitialized = true;
    }
  }
  return isNewArchEnabledCache;
};

export class NativeLoggerListener {
  private static isInitialized = false;

  static async initialize(): Promise<void> {
    // Prevent multiple registrations of the same log listener
    if (this.isInitialized) {
      return Promise.resolve();
    }

    // Using console.log will log to the JavaScript side but prevent
    // React Native's default behavior of redirecting logs to the native side.
    // By doing it asynchronously, we ensure the logs are captured on both
    // the JavaScript and native ends.
    const logEvent = async (event: {
      logLevel: CioLogLevel;
      message: string;
    }) => {
      switch (event.logLevel) {
        case CioLogLevel.Debug:
          console.debug(loggerPrefix + event.message);
          break;
        case CioLogLevel.Info:
          console.info(loggerPrefix + event.message);
          break;
        case CioLogLevel.Error:
          console.error(loggerPrefix + event.message);
          break;
        default:
          console.log(loggerPrefix + event);
          break;
      }
    };

    const logHandler = (data: any) => {
      const event = data as { logLevel: CioLogLevel; message: string };
      logEvent(event);
    };

    // Determine architecture and setup appropriate event listener
    const newArchEnabled = await isNewArchEnabled();
    withNativeModule((native) => {
      if (newArchEnabled) {
        // Use TurboModule event system
        native.onCioLogEvent(logHandler);
      } else {
        // Use legacy NativeEventEmitter
        const bridge = new NativeEventEmitter(native);
        bridge.addListener('CioLogEvent', logHandler);
      }
    });
    this.isInitialized = true;
  }
}
