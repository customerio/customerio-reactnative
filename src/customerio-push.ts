import { AppRegistry, Platform, type TurboModule } from 'react-native';
import { NativeLoggerListener } from './native-logger-listener';
import NativeCustomerIOMessagingPush, {
  type Spec as CodegenSpec,
} from './specs/modules/NativeCustomerIOMessagingPush';
import {
  type CioBackgroundPush,
  type CioBackgroundPushHandler,
  type CioPushPermissionOptions,
  CioPushPermissionStatus,
} from './types';
import { callNativeModule, ensureNativeModule } from './utils/native-bridge';

/**
 * Ensures all methods defined in codegen spec are implemented by the public module
 *
 * @internal
 */
interface NativePushSpec extends Omit<
  CodegenSpec,
  | keyof TurboModule
  | 'registerBackgroundPushHandler'
  | 'unregisterBackgroundPushHandler'
  | 'acknowledgeBackgroundPush'
  | 'onBackgroundPushReceived'
> {}

// Reference to the native CustomerIO Data Pipelines module for SDK operations
const nativeModule = ensureNativeModule(NativeCustomerIOMessagingPush);

// Wrapper function that ensures SDK is initialized before calling native methods
const withNativeModule = <R>(fn: (native: CodegenSpec) => R): R => {
  return callNativeModule(nativeModule, fn);
};

// Keep in sync with `TASK_KEY` in ReactBackgroundPush.kt.
const BACKGROUND_PUSH_TASK = 'CustomerIOBackgroundPush';

type BackgroundPushEvent = { id: string; push: CioBackgroundPush };

let backgroundPushHandler: CioBackgroundPushHandler | undefined;
let backgroundPushSubscription: { remove(): void } | undefined;
let backgroundPushListening = false;

// Runs the handler, then acknowledges the push so native can end the OS's background time.
const handleBackgroundPush = async (event: BackgroundPushEvent) => {
  try {
    await backgroundPushHandler?.(event.push);
  } catch (error) {
    NativeLoggerListener.warn('Silent push handler failed:', error);
  }
  withNativeModule((native) => native.acknowledgeBackgroundPush(event.id));
};

/** @public */
class CustomerIOPushMessaging implements NativePushSpec {
  /**
   * Processes push notification received outside the CIO SDK. The method displays notification on
   * device and tracks CIO metrics for push notification.
   *
   * @param message - push payload received from FCM. The payload must contain data payload received in push
   * notification.
   * @param handleNotificationTrigger - indicates whether it should display the notification or not.
   * true (default): The SDK will display the notification and track associated metrics.
   * false: The SDK will only process the notification to track metrics but will not display any notification.
   * @returns promise that resolves to boolean indicating if the notification was handled by the SDK or not.
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
      return withNativeModule((native) =>
        native.onMessageReceived(message, handleNotificationTrigger)
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

  /**
   * Track push notifications metrics using this method.
   * Call this method when a user interacts and taps open the push notification.
   * @param payload - Customer.io payload as received from the push notification
   */
  trackNotificationResponseReceived(payload: Object) {
    // Tracking push notification metrics on Android is handled automatically
    // through the Google Services API, so there is no need to make a specific call for it.
    // This method is specific to iOS and works as expected on Android without any additional intervention.
    if (payload == null || this.isAndroid()) {
      return;
    }
    withNativeModule((native) =>
      native.trackNotificationResponseReceived(payload)
    );
  }

  /**
   * Track push notifications metrics using this method.
   * Call this method when a push notification is received.
   * @param payload - Customer.io payload as received from the push notification
   */
  trackNotificationReceived(payload: Object) {
    // Tracking push notification metrics on Android is handled automatically
    // through the Google Services API, so there is no need to make a specific call for it.
    // This method is specific to iOS and works as expected on Android without any additional intervention.
    if (payload == null || this.isAndroid()) {
      return;
    }
    withNativeModule((native) => native.trackNotificationReceived(payload));
  }

  /**
   * Get the registered device token for the app.
   * @returns Promise with device token as a string, or error if no token is
   * registered or the method fails to fetch token.
   */
  getRegisteredDeviceToken(): Promise<string> {
    return withNativeModule((native) => native.getRegisteredDeviceToken());
  }

  showPromptForPushNotifications(
    options: CioPushPermissionOptions = { ios: { badge: true, sound: true } }
  ): Promise<CioPushPermissionStatus> {
    return withNativeModule((native) =>
      native.showPromptForPushNotifications(options)
    ).then((status) => status as CioPushPermissionStatus);
  }

  getPushPermissionStatus(): Promise<CioPushPermissionStatus> {
    return withNativeModule((native) => native.getPushPermissionStatus()).then(
      (status) => status as CioPushPermissionStatus
    );
  }

  /**
   * Sets the handler for Customer.io silent pushes. Call it at the top level of your entry file
   * (`index.js`), before `AppRegistry.registerComponent`: on Android, a silent push that starts the
   * app in the background runs that file without mounting your app.
   *
   * The SDK waits up to 25 seconds for the returned promise, including the time React Native takes
   * to start. Setting a new handler replaces the previous one.
   *
   * @param handler - receives each silent push
   * @returns a subscription whose `remove()` stops delivery to this handler
   */
  setBackgroundPushHandler(handler: CioBackgroundPushHandler): {
    remove(): void;
  } {
    return withNativeModule((native) => {
      if (!backgroundPushListening) {
        if (Platform.OS === 'android') {
          AppRegistry.registerHeadlessTask(
            BACKGROUND_PUSH_TASK,
            () => handleBackgroundPush
          );
        } else {
          native.onBackgroundPushReceived((event) =>
            handleBackgroundPush(event as BackgroundPushEvent)
          );
        }
        backgroundPushListening = true;
      }
      backgroundPushHandler = handler;
      native.registerBackgroundPushHandler();

      const subscription = {
        remove: () => {
          if (backgroundPushSubscription !== subscription) {
            return;
          }
          backgroundPushSubscription = undefined;
          backgroundPushHandler = undefined;
          native.unregisterBackgroundPushHandler();
        },
      };
      backgroundPushSubscription = subscription;
      return subscription;
    });
  }

  isAndroid(): boolean {
    return Platform.OS === 'android';
  }
}

export { CustomerIOPushMessaging };
