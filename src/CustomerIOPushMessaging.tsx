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
  /**
   * Handles push notification received to help processing push notifications received outside the CIO SDK.
   *
   * @param message push payload received from FCM.
   * @param handleNotificationTrigger indicating if the local notification should be triggered.
   * @return promise that resolves to boolean indicating whether this was handled by CustomerIO or not.
   */
  onMessageReceived(
    message: any,
    handleNotificationTrigger: boolean
  ): Promise<boolean> {
    if (Platform.OS === 'ios') {
      // Since push notifications on iOS work fine with multiple notification services,
      // We don't need to process them on iOS for now.
      // Resolving promise to true makes it easier for callers to avoid adding
      // unnecessary platform specific checks.
      return Promise.resolve(true);
    } else {
      return PushMessagingNative.handleMessage(
        message,
        handleNotificationTrigger
      );
    }
  }
}

export { CustomerIOPushMessaging };
