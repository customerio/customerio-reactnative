import { NativeEventEmitter, NativeModules, Platform } from 'react-native';
import type { InAppEventType } from './CustomerioEnum';

const LINKING_ERROR =
  `The package 'customerio-reactnative' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

/**
 * Get CustomerioInAppMessaging native module
 */
const InAppMessagingNative = NativeModules.CustomerioInAppMessaging
  ? NativeModules.CustomerioInAppMessaging
  : new Proxy(
    {},
    {
      get() {
        throw new Error(LINKING_ERROR);
      },
    }
  );

// Constant value used for emitting all events for in-app from native modules
const InAppEventListenerEventName = 'InAppEventListener';

/**
 * Helper class so that registering event listeners is easier for customers.
 */
class CustomerIOInAppMessaging {
  eventEmitter: NativeEventEmitter = new NativeEventEmitter(InAppMessagingNative);

  registerEventsListener(listener: (eventType: InAppEventType, data: any) => void) {
    return this.eventEmitter.addListener(InAppEventListenerEventName, (event: any) => {
      // Make sure all supported events are added to InAppEventType, else it will throw an error
      listener(event.eventType as InAppEventType, event.data)
    });
  }
}

export { CustomerIOInAppMessaging };
