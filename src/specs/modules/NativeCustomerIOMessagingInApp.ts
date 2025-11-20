import { TurboModuleRegistry, type TurboModule } from 'react-native';
import type {
  Double,
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
  // Old architecture support: EventEmitter requires these methods for proper functionality
  /** @internal - Registers an event listener for old architecture EventEmitter */
  addListener: (eventName: string) => void;
  /** @internal - Removes event listeners for old architecture EventEmitter */
  removeListeners: (count: Double) => void;
}

export default TurboModuleRegistry.getEnforcing<Spec>(
  'NativeCustomerIOMessagingInApp'
);
