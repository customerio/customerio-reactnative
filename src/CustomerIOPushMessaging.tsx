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
   * Processes push notification received outside the CIO SDK. The method displays notification on
   * device and tracks CIO metrics for push notification.
   *
   * @param message push payload received from FCM. The payload must contain data payload received in push
   * notification.
   * @param handleNotificationTrigger indicates whether it should display the notification or not.
   * true (default): The SDK will display the notification and track associated metrics.
   * false: The SDK will only process the notification to track metrics but will not display any notification.
   * @return promise that resolves to boolean indicating if the notification was handled by the SDK or not.
   */
  onMessageReceived(
    message: any,
    handleNotificationTrigger: boolean = true
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

  /**
   * Handles push notification received when app is background. Since FCM itself displays the notification
   * when app is background, this method makes it easier to determine whether the notification should be
   * displayed or not.
   *
   * @see [onMessageReceived] for more details
   */
  onBackgroundMessageReceived(message: any): Promise<boolean> {
    return this.onMessageReceived(message, !message.notification);
  }
}

export { CustomerIOPushMessaging };
