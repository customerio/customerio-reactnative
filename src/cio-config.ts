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
