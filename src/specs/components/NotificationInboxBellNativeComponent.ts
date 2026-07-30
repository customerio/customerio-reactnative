// React Native docs now recommend Codegen types should be imported from the react-native package
// But it breaks on Expo and older React Native versions, so we import from react-native/Libraries/Types/CodegenTypes
// for compatibility with all versions until we can fully migrate to the new import style without breaking older versions
// https://reactnative.dev/docs/strict-typescript-api#codegen-types-should-now-be-imported-from-the-react-native-package

import type { HostComponent, ViewProps } from 'react-native';
/* eslint-disable @react-native/no-deep-imports */
import type { DirectEventHandler } from 'react-native/Libraries/Types/CodegenTypes';
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

/** Event data for inbox bell taps. Carries no payload; presence indicates a tap. */
export interface BellTapEvent {}

/** Props for the native NotificationInboxBell component. */
export interface NativeProps extends ViewProps {
  /** Fired when the user taps the bell. Host should present its own inbox UI. */
  onTap?: DirectEventHandler<BellTapEvent>;
}

// React Native Codegen automatically generates the native component bridge based on the NativeProps interface.
// Public view is NotificationInboxBellView in the components directory.
export default codegenNativeComponent<NativeProps>(
  'NotificationInboxBellNative'
) as HostComponent<NativeProps>;
