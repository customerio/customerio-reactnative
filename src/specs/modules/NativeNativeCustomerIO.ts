import { type TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  // Initialization
  initialize(config: Object, args: Object): void;

  // Customer identification
  identify(userId?: string, traits?: Object): void;
  clearIdentify(): void;

  // Event tracking
  track(name: string, properties?: Object): void;
  screen(title: string, properties?: Object): void;

  // Profile and device attributes
  setProfileAttributes(attributes: Object): void;
  setDeviceAttributes(attributes: Object): void;

  // Device token management
  registerDeviceToken(token: string): void;
  deleteDeviceToken(): void;

  // Push permission methods (delegated to push module)
  getPushPermissionStatus(): Promise<string>;
  showPromptForPushNotifications(options?: Object): Promise<string>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('NativeCustomerIO');
