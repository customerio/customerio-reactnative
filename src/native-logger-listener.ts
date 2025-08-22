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

/* @internal */
export class NativeLoggerListener {
  private static isInitialized = false;
  // Prefix for all CustomerIO log messages
  private static loggerPrefix = '[CIO] ';

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
          console.debug(this.loggerPrefix + event.message);
          break;
        case CioLogLevel.Info:
          console.info(this.loggerPrefix + event.message);
          break;
        case CioLogLevel.Error:
          console.error(this.loggerPrefix + event.message);
          break;
        default:
          console.log(this.loggerPrefix + event);
          break;
      }
    };

    const logHandler = (data: any) => {
      const event = data as { logLevel: CioLogLevel; message: string };
      logEvent(event);
    };

    withNativeModule((native) => {
      try {
        // Try new arch TurboModule log listener (not available in old arch)
        native.onCioLogEvent(logHandler);
      } catch {
        // Fallback to old arch NativeEventEmitter when new arch method fails
        try {
          // Use try-catch to prevent crashes for cases where native module may
          // not be available instantly
          const bridge = new NativeEventEmitter(native);
          bridge.addListener('CioLogEvent', logHandler);
        } catch (error) {
          NativeLoggerListener.warn(
            'Failed to attach old arch log listener:',
            error
          );
        }
      }
    });
    this.isInitialized = true;
  }

  // Logs warning messages in development mode only, with CIO prefix
  static warn(message: string, error?: unknown) {
    if (__DEV__) {
      console.warn(this.loggerPrefix + message, error);
    }
  }

  // Initializes native logger listener with error handling
  static initNativeLogger() {
    try {
      NativeLoggerListener.initialize();
    } catch (error) {
      NativeLoggerListener.warn('Failed to initialize native logger:', error);
    }
  }
}
