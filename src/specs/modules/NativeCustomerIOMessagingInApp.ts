import {
  CodegenTypes,
  TurboModuleRegistry,
  type TurboModule,
} from 'react-native';

/**
 * Native module specification for CustomerIO In-App Messaging React Native SDK
 *
 * @see NativeCustomerIO.ts for detailed documentation on TurboModule patterns,
 * Codegen compatibility, and type safety approach.
 */

/** Generic object type for native bridge data exchange */
type NativeBridgeObject = Object;

/** TurboModule interface for CustomerIO In-App Messaging native operations */
export interface Spec extends TurboModule {
  dismissMessage(): void;
  readonly onInAppEventReceived: CodegenTypes.EventEmitter<NativeBridgeObject>;
  /** @internal - Added because React Native has no simpler way to check for New Architecture */
  isNewArchEnabled(): Promise<boolean>;
  // Old architecture support: EventEmitter requires these methods for proper functionality
  /** @internal - Registers an event listener for old architecture EventEmitter */
  addListener: (eventName: string) => void;
  /** @internal - Removes event listeners for old architecture EventEmitter */
  removeListeners: (count: CodegenTypes.Double) => void;
}

export default TurboModuleRegistry.getEnforcing<Spec>(
  'NativeCustomerIOMessagingInApp'
);
