export {
  CioLogLevel,
  CioRegion,
  PushClickBehaviorAndroid,
  ScreenView,
} from './specs/modules/NativeCustomerIO';
export type { CioConfig } from './specs/modules/NativeCustomerIO';

export type CioPushPermissionOptions = {
  ios?: {
    badge: boolean;
    sound: boolean;
  };
};

export enum CioPushPermissionStatus {
  Granted = 'GRANTED',
  Denied = 'DENIED',
  NotDetermined = 'NOTDETERMINED',
}
