import { NativeEventEmitter, NativeModules, Platform } from 'react-native';

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

  registerEventsListener(listener: (event: InAppMessageEvent) => void) {
    return this.eventEmitter.addListener(InAppEventListenerEventName, (data: any) => {
      // Make sure all supported events are added to InAppMessageEventType, else it will throw an error
      let event = new InAppMessageEvent(
        data.eventType as InAppMessageEventType,
        data.messageId,
        data.messageId,
        data.actionValue,
        data.actionName);
      listener(event)
    });
  }
}

/**
 * Enum to represent the type of event triggered by in-app event callback.
 */
enum InAppMessageEventType {
  errorWithMessage = "errorWithMessage",
  messageActionTaken = "messageActionTaken",
  messageDismissed = "messageDismissed",
  messageShown = "messageShown",
}

/**
 * Class to hold in-app event attributes.
 */
class InAppMessageEvent {
  eventType: InAppMessageEventType
  messageId: string
  deliveryId?: string
  actionValue?: string
  actionName?: string

  constructor(eventType: InAppMessageEventType, messageId: string, deliveryId?: string, actionValue?: string, actionName?: string) {
    this.eventType = eventType;
    this.deliveryId = deliveryId;
    this.messageId = messageId;
    this.actionValue = actionValue;
    this.actionName = actionName;
  }
}

export { CustomerIOInAppMessaging, InAppMessageEventType, InAppMessageEvent };
