import { TurboModuleRegistry, type TurboModule } from 'react-native';

/**
 * Native module specification for CustomerIO Push Messaging React Native SDK
 *
 * @see NativeCustomerIO.ts for detailed documentation on TurboModule patterns,
 * Codegen compatibility, and type safety approach.
 */

type NativeBridgeObject = Object;
export interface Spec extends TurboModule {
  onMessageReceived(
    message: NativeBridgeObject,
    handleNotificationTrigger: boolean
  ): Promise<boolean>;
  trackNotificationResponseReceived(payload: NativeBridgeObject): void;
  trackNotificationReceived(payload: NativeBridgeObject): void;
  getRegisteredDeviceToken(): Promise<string>;
  showPromptForPushNotifications(options: NativeBridgeObject): Promise<string>;
  getPushPermissionStatus(): Promise<string>;
}

export default TurboModuleRegistry.getEnforcing<Spec>(
  'NativeCustomerIOMessagingPush'
);
