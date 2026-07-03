import { TurboModuleRegistry, type TurboModule } from 'react-native';

/**
 * Native module specification for CustomerIO Geofence React Native SDK
 *
 * @see NativeCustomerIO.ts for detailed documentation on TurboModule patterns,
 * Codegen compatibility, and type safety approach.
 */

export interface Spec extends TurboModule {
  refreshFromCurrentLocation(): void;
}

export default TurboModuleRegistry.get<Spec>('NativeCustomerIOGeofence');
