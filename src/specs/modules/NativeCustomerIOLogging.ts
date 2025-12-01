import { TurboModuleRegistry, type TurboModule } from 'react-native';
import type {
  EventEmitter,
  UnsafeObject,
} from 'react-native/Libraries/Types/CodegenTypes';

/**
 * Native module specification for CustomerIO Logging React Native SDK
 *
 * This module defines the TurboModule interface for CustomerIO logging bridge.
 * Used internally for printing logs to React Native environment instead of native.
 *
 * @see NativeCustomerIO.ts for detailed documentation on TurboModule patterns,
 * Codegen compatibility, and type safety approach.
 */

/** TurboModule interface for CustomerIO logging native operations */
export interface Spec extends TurboModule {
  readonly onCioLogEvent: EventEmitter<UnsafeObject>;
}

export default TurboModuleRegistry.getEnforcing<Spec>(
  'NativeCustomerIOLogging'
);
