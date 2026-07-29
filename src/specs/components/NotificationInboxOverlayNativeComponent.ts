// React Native docs now recommend Codegen types should be imported from the react-native package
// But it breaks on Expo and older React Native versions, so we import from react-native/Libraries/Types/CodegenTypes
// for compatibility with all versions until we can fully migrate to the new import style without breaking older versions
// https://reactnative.dev/docs/strict-typescript-api#codegen-types-should-now-be-imported-from-the-react-native-package

import type { HostComponent, ViewProps } from 'react-native';
/* eslint-disable @react-native/no-deep-imports */
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

/**
 * Props for the native NotificationInboxOverlay component.
 *
 * The overlay takes no props of its own: it owns panel presentation internally on both platforms
 * (iOS presents a sheet with system detents), and per-message actions are delivered through the
 * global InboxEventListener rather than per-component callbacks.
 */
export interface NativeProps extends ViewProps {}

// React Native Codegen automatically generates the native component bridge based on the NativeProps interface.
// Public view is NotificationInboxOverlayView in the components directory.
export default codegenNativeComponent<NativeProps>(
  'NotificationInboxOverlayNative'
) as HostComponent<NativeProps>;
