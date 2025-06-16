import { type TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  // Push message handling
  handleMessage(
    message: Object,
    handleNotificationTrigger: boolean
  ): Promise<boolean>;

  // Push notification tracking
  trackNotificationResponseReceived(payload: Object): void;
  trackNotificationReceived(payload: Object): void;

  // Device token management
  getRegisteredDeviceToken(): Promise<string>;

  // Push permissions
  showPromptForPushNotifications(options?: Object): Promise<string>;
  getPushPermissionStatus(): Promise<string>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('CioRctPushMessaging');
