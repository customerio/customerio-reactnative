import {
  NativeEventEmitter,
  type EventSubscription,
  type TurboModule,
} from 'react-native';
import { InlineInAppMessageView } from './components';
import { NativeLoggerListener } from './native-logger-listener';
import NativeCustomerIOMessagingInApp, {
  type Spec as CodegenSpec,
} from './specs/modules/NativeCustomerIOMessagingInApp';
import type { InAppMessageEventType } from './types';
import { callNativeModule, ensureNativeModule } from './utils/native-bridge';

// Constant value used for emitting all events for in-app from native modules
const InAppEventListenerEventName = 'InAppEventListener';

/**
 * Ensures all methods defined in codegen spec are implemented by the public module
 *
 * @internal
 */
interface NativeInAppSpec
  extends Omit<
    CodegenSpec,
    | keyof TurboModule
    | 'onInAppEventReceived'
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
 *
 * @public
 */
class CustomerIOInAppMessaging implements NativeInAppSpec {
  registerEventsListener(
    listener: (event: InAppMessageEvent) => void
  ): EventSubscription {
    const emitter = (data: any) => {
      // Convert raw native payload to InAppMessageEvent
      const event = new InAppMessageEvent(
        data.eventType as InAppMessageEventType,
        data.messageId,
        data.deliveryId,
        data.actionValue,
        data.actionName
      );
      listener(event);
    };

    return withNativeModule((native) => {
      try {
        // Try new arch TurboModule event listener (not available in old arch)
        return native.onInAppEventReceived(emitter);
      } catch {
        NativeLoggerListener.warn(
          'Falling back to legacy event emitter (likely using old architecture). ' +
            'Switch to new architecture for better performance and event handling.'
        );
        // Fallback to old arch NativeEventEmitter when new arch method fails
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
/** @public */
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
