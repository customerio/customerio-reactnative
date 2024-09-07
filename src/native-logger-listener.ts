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
    bridge.addListener(
      'CioLogEvent',
      (event: { logLevel: CioLogLevel; message: string }) => {
        console.log("I received the value here-->", event.message) // "someValue"
        // Using console.log will log to the JavaScript side but prevent
        // React Native’s default behavior of redirecting logs to the native side.
        // By doing it asynchronously, we ensure the logs are captured on both
        // the JavaScript and native ends.
        async function log() {
          switch (event.logLevel) {
            case CioLogLevel.Debug:
              console.debug("[CIO] " + event.message);
              break;
            case CioLogLevel.Info:
              console.info("[CIO] " + event.message);
              break;
            case CioLogLevel.Error:
              console.error("[CIO] " + event.message);
              break;
            default:
              console.log("[CIO] " + event);
              break;
          }
        }
        log();
      }
    );
  }
}
