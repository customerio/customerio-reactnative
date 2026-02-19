import { TurboModuleRegistry, type TurboModule } from 'react-native';
import type {
  EventEmitter,
  UnsafeObject,
} from 'react-native/Libraries/Types/CodegenTypes';

/**
 * Native module specification for CustomerIO In-App Messaging React Native SDK
 *
 * @see NativeCustomerIO.ts for detailed documentation on TurboModule patterns,
 * Codegen compatibility, and type safety approach.
 */

/** TurboModule interface for CustomerIO In-App Messaging native operations */
export interface Spec extends TurboModule {
  dismissMessage(): void;
  readonly onInAppEventReceived: EventEmitter<UnsafeObject>;
  // Notification Inbox related methods
  setupInboxListener(): void;
  readonly subscribeToMessagesChanged: EventEmitter<UnsafeObject>;
  getMessages(topic?: string): Promise<UnsafeObject[]>;
  markMessageOpened(message: UnsafeObject): void;
  markMessageUnopened(message: UnsafeObject): void;
  markMessageDeleted(message: UnsafeObject): void;
  trackMessageClicked(message: UnsafeObject, actionName?: string): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>(
  'NativeCustomerIOMessagingInApp'
);
