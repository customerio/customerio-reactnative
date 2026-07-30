// React Native docs now recommend Codegen types should be imported from the react-native package
// But it breaks on Expo and older React Native versions, so we import from react-native/Libraries/Types/CodegenTypes
// for compatibility with all versions until we can fully migrate to the new import style without breaking older versions
// https://reactnative.dev/docs/strict-typescript-api#codegen-types-should-now-be-imported-from-the-react-native-package

import type { HostComponent, ViewProps } from 'react-native';
/* eslint-disable @react-native/no-deep-imports */
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

/**
 * Props for the native NotificationInboxView component (the Jist-rendered message list).
 * No required props; the host controls sizing via standard ViewProps style.
 * Message actions are handled by the existing global InboxEventListener, so this
 * component needs no per-component action callback.
 */
export interface NativeProps extends ViewProps {}

// React Native Codegen automatically generates the native component bridge based on the NativeProps interface.
// Public view is NotificationInboxView in the components directory.
export default codegenNativeComponent<NativeProps>(
  'NotificationInboxViewNative'
) as HostComponent<NativeProps>;
