import type { HostComponent, ViewProps } from 'react-native';
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

/** Props for the native inline message component. */
export interface NativeProps extends ViewProps {
  /** Required element ID for retrieving inline message content. */
  elementId: string;
  onSizeChange: DirectEventHandler<SizeChangeEvent>;
  onStateChange?: DirectEventHandler<StateChangeEvent>;
}

// React Native Codegen automatically generates the native component bridge based on the NativeProps interface
// This creates the low-level native component that handles communication between JS and native code
// Used by native iOS/Android components - the public view is InlineInAppMessageView in components directory
export default codegenNativeComponent<NativeProps>(
  'InlineMessageNative'
) as HostComponent<NativeProps>;
