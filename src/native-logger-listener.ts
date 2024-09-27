import { NativeEventEmitter, NativeModules, Platform } from 'react-native';
import { CioLogLevel } from './cio-config';

const LINKING_ERROR =
  `The package 'customerio-reactnative' doesn't seem to be linked. Make sure: ` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const CioLoggingEmitter = NativeModules.CioLoggingEmitter
  ? NativeModules.CioLoggingEmitter
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

export class NativeLoggerListener {
  static initialize() {
    const bridge = new NativeEventEmitter(CioLoggingEmitter);
    const loggerPrefix = '[CIO] ';
    bridge.addListener(
      'CioLogEvent',
      (event: { logLevel: CioLogLevel; message: string }) => {
        // Using console.log will log to the JavaScript side but prevent
        // React Native’s default behavior of redirecting logs to the native side.
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
      }
    );
  }
}
