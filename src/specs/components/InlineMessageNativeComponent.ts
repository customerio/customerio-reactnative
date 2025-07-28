// React Native docs now recommend Codegen types should be imported from the react-native package
// But it breaks on Expo and older React Native versions, so we import from react-native/Libraries/Types/CodegenTypes
// for compatibility with all versions until we can fully migrate to the new import style without breaking older versions
// https://reactnative.dev/docs/strict-typescript-api#codegen-types-should-now-be-imported-from-the-react-native-package

import type { HostComponent, ViewProps } from 'react-native';
/* eslint-disable @react-native/no-deep-imports */
import type {
  DirectEventHandler,
  Double,
} from 'react-native/Libraries/Types/CodegenTypes';
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

/** Event data for inline message size changes. */
export interface SizeChangeEvent {
  width: Double;
  height: Double;
  duration?: Double;
}

/** States representing the loading and display status of inline messages. */
export enum InlineMessageState {
  LoadingStarted = 'LoadingStarted',
  LoadingFinished = 'LoadingFinished',
  NoMessageToDisplay = 'NoMessageToDisplay',
}

/** Event data for inline message state changes. */
export interface StateChangeEvent {
  state: string;
}

/** Event data for inline message action clicks. */
export interface ActionClickEvent {
  /** Message data structure - defined inline for codegen compatibility (cannot import types) */
  message: {
    messageId: string;
    deliveryId?: string;
    elementId?: string;
  };
  actionValue: string;
  actionName: string;
}

/** Props for the native inline message component. */
export interface NativeProps extends ViewProps {
  /** Required element ID for retrieving inline message content. */
  elementId: string;
  onSizeChange: DirectEventHandler<SizeChangeEvent>;
  onStateChange?: DirectEventHandler<StateChangeEvent>;
  onActionClick?: DirectEventHandler<ActionClickEvent>;
}

// React Native Codegen automatically generates the native component bridge based on the NativeProps interface
// This creates the low-level native component that handles communication between JS and native code
// Used by native iOS/Android components - the public view is InlineInAppMessageView in components directory
export default codegenNativeComponent<NativeProps>(
  'InlineMessageNative'
) as HostComponent<NativeProps>;
