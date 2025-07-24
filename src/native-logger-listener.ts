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

export class NativeLoggerListener {
  private static isInitialized = false;

  static async initialize() {
    // Prevent multiple registrations of the same log listener
    if (this.isInitialized) {
      return;
    }
    const loggerPrefix = '[CIO] ';

    const logHandler = (data: any) => {
      const event = data as { logLevel: CioLogLevel; message: string };
      // Using console.log will log to the JavaScript side but prevent
      // React Native's default behavior of redirecting logs to the native side.
      // By doing it asynchronously, we ensure the logs are captured on both
      // the JavaScript and native ends.
      async function log() {
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
      }
      log();
    };

    return withNativeModule(async (native) => {
      // Check if new architecture is enabled
      const isNewArch = await native.isNewArchEnabled();

      if (isNewArch) {
        // New architecture: Use TurboModule event emitter
        return native.onCioLogEvent(logHandler);
      } else {
        // Old architecture: Use legacy NativeEventEmitter
        const bridge = new NativeEventEmitter(native);
        return bridge.addListener('CioLogEvent', logHandler);
      }
    }).finally(() => {
      this.isInitialized = true;
    });
  }
}
