import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'customerio-reactnative' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

/**
 * Get CustomerIOPushMessaging native module
 */
const PushMessagingNative = NativeModules.CustomerioPushMessaging
  ? NativeModules.CustomerioPushMessaging
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

class CustomerIOPushMessaging {
  onMessageReceived(message: any): Promise<boolean> {
    if (Platform.OS === 'ios') {
      return Promise.resolve(true);
    } else {
      return PushMessagingNative.handleMessage(message);
    }
  }
}

export { CustomerIOPushMessaging };
