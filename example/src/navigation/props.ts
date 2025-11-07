import { NavigationProp } from '@react-navigation/native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { TrackEvent, User } from '@utils';
import { CioConfig, CioPushPermissionStatus } from 'customerio-reactnative';

export const SettingsScreenName = 'Settings' as const;
export const HomeScreenName = 'Customer.io' as const;
export const LoginScreenName = 'Login' as const;
export const TrackScreenName = 'Track' as const;
export const CustomProfileAttrScreenName = 'Profile Attributes' as const;
export const CustomDeviceAttrScreenName = 'Device Attributes' as const;
export const InternalSettingsScreenName = 'Internal Settings' as const;
export const InlineExamplesScreenName = 'Inline Examples' as const;

export type NavigationStackParamList = {
  [SettingsScreenName]: undefined;
  [HomeScreenName]: undefined;
  [LoginScreenName]: undefined;
  [TrackScreenName]: undefined;
  [TrackScreenName]: undefined;
  [CustomProfileAttrScreenName]: undefined;
  [CustomDeviceAttrScreenName]: undefined;
  [InternalSettingsScreenName]: undefined;
  [InlineExamplesScreenName]: undefined;
};

export type NavigationProps = NavigationProp<NavigationStackParamList>;

export type NavigationScreenProps<T extends keyof NavigationStackParamList> =
  NativeStackScreenProps<NavigationStackParamList, T>;

export type ContentNavigatorCallbacks = {
  onSetConfig: (config: CioConfig) => void;
  onLogin: (user: User) => void;
  onLogout: () => void;
  onTrackEvent: (event: TrackEvent) => void;
  onProfileAttributes: (attributes: Record<string, any>) => void;
  onDeviceAttributes: (attributes: Record<string, any>) => void;
  onScreenChange: (screenName: string) => void;
  onPushNotificationRequestPermissionButtonPress: () => Promise<CioPushPermissionStatus>;
};
