import { TurboModuleRegistry, type TurboModule } from 'react-native';

/**
 * Native module specification for CustomerIO Location React Native SDK
 *
 * @see NativeCustomerIO.ts for detailed documentation on TurboModule patterns,
 * Codegen compatibility, and type safety approach.
 */

export interface Spec extends TurboModule {
  setLastKnownLocation(latitude: number, longitude: number): void;
  requestLocationUpdate(): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>(
  'NativeCustomerIOLocation'
);
