import {
  NativeEventEmitter,
  type EmitterSubscription,
  type TurboModule,
} from 'react-native';
import { InlineInAppMessageView } from './components';
import { isNewArchEnabled } from './native-logger-listener';
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
 */
class CustomerIOInAppMessaging implements NativeInAppSpec {
  registerEventsListener(listener: (event: InAppMessageEvent) => void) {
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

    // Holds the real subscription once created
    let actualSubscription: EmitterSubscription;
    let removed = false;

    // Proxy object returned immediately to keep the API consistent
    const proxySubscription = {
      remove: () => {
        removed = true;
        actualSubscription?.remove();
      },
      emitter: new NativeEventEmitter(),
      eventType: InAppEventListenerEventName,
      listener: emitter,
      context: undefined,
      key: 0,
      subscriber: {} as any,
    } as EmitterSubscription;

    // Setup listener asynchronously based on architecture
    withNativeModule(async (native) => {
      const newArchEnabled = await isNewArchEnabled();
      if (newArchEnabled) {
        // Use TurboModule emitter for new architecture
        const subscriber = native.onInAppEventReceived(emitter);
        actualSubscription = {
          ...proxySubscription,
          remove: () => subscriber.remove(),
        } as unknown as EmitterSubscription;
      } else {
        // Use legacy NativeEventEmitter for old architecture
        const eventEmitter = new NativeEventEmitter(native);
        actualSubscription = eventEmitter.addListener(
          InAppEventListenerEventName,
          emitter
        );
      }

      // Handle case where .remove() was called before subscription was ready
      if (removed) {
        actualSubscription?.remove();
      }
    });

    return proxySubscription;
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
