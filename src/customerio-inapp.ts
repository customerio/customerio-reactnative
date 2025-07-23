import { NativeEventEmitter, type TurboModule } from 'react-native';
import { InlineInAppMessageView } from './components';
import NativeCustomerIOMessagingInApp, {
  type Spec as CodegenSpec,
} from './specs/modules/NativeCustomerIOMessagingInApp';
import type { InAppMessageEventType } from './types';
import { callNativeModule, ensureNativeModule } from './utils/native-bridge';

// Constant value used for emitting all events for in-app from native modules
const InAppEventListenerEventName = 'InAppEventListener';

// Ensures all methods defined in codegen spec are implemented by the public module
interface NativeSpec
  extends Omit<
    CodegenSpec,
    | keyof TurboModule
    | 'onInAppEventReceived'
    | 'isNewArchEnabled'
    | 'addListener'
    | 'removeListeners'
  > {}

// Reference to the native CustomerIO Data Pipelines module for SDK operations
const nativeModule = ensureNativeModule(NativeCustomerIOMessagingInApp);

// Wrapper function that ensures SDK is initialized before calling native methods
const withNativeModule = <R>(fn: (native: CodegenSpec) => R): R => {
  return callNativeModule(nativeModule, fn);
};

/**
 * Helper class so that registering event listeners is easier for customers.
 */
class CustomerIOInAppMessaging implements NativeSpec {
  registerEventsListener(listener: (event: InAppMessageEvent) => void) {
    const emitter = (data: any) => {
      // Construct a proper InAppMessageEvent instance
      const event = new InAppMessageEvent(
        data.eventType as InAppMessageEventType,
        data.messageId,
        data.deliveryId,
        data.actionValue,
        data.actionName
      );
      listener(event);
    };

    return withNativeModule(async (native) => {
      // Old arch requires async return via Promise; new arch supports sync
      const isNewArch = await native.isNewArchEnabled();
      if (isNewArch) {
        // If the new architecture is enabled, use the TurboModule's event emitter
        return native.onInAppEventReceived(emitter);
      } else {
        // If the new architecture is not enabled, use the legacy event emitter
        const eventEmitter = new NativeEventEmitter(native);
        return eventEmitter.addListener(InAppEventListenerEventName, emitter);
      }
    });
  }

  /**
   * Dismisses any currently displayed in-app message
   */
  dismissMessage() {
    withNativeModule((native) => native.dismissMessage());
  }
}

/**
 * Class to hold in-app event attributes.
 */
class InAppMessageEvent {
  eventType: InAppMessageEventType;
  messageId: string;
  deliveryId?: string;
  actionValue?: string;
  actionName?: string;

  constructor(
    eventType: InAppMessageEventType,
    messageId: string,
    deliveryId?: string,
    actionValue?: string,
    actionName?: string
  ) {
    this.eventType = eventType;
    this.deliveryId = deliveryId;
    this.messageId = messageId;
    this.actionValue = actionValue;
    this.actionName = actionName;
  }
}

// Export in-app messaging types and components for simplified imports
export type { InlineInAppMessageViewProps } from './components';
export { CustomerIOInAppMessaging, InAppMessageEvent, InlineInAppMessageView };
