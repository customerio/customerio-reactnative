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
        // if we just use console.log, it will log to the JS side but it will prevent RN default behavior of redirecting logs to the native side
        // doing it async allows to be logged to the JS side and then to the native side
        async function log() {
          switch (event.logLevel) {
            case CioLogLevel.Debug:
              console.debug(event.message);
              break;
            case CioLogLevel.Info:
              console.info(event.message);
              break;
            case CioLogLevel.Error:
              console.error(event.message);
              break;
            default:
              console.log(event);
              break;
          }
        }
        log();
      }
    );
  }
}
