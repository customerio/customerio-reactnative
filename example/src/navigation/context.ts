import { CioPushPermissionStatus } from 'customerio-reactnative';
import { createContext } from 'react';
import { ContentNavigatorCallbacks } from './props';

export const NavigationCallbackContext =
  createContext<ContentNavigatorCallbacks>({
    onSetConfig: () => {},
    onLogin: () => {},
    onLogout: () => {},
    onTrackEvent: () => {},
    onProfileAttributes: () => {},
    onDeviceAttributes: () => {},
    onScreenChange: () => {},
    onPushNotificationRequestPermissionButtonPress: async () => CioPushPermissionStatus.NotDetermined,
  });
