import type { HostComponent, ViewProps } from 'react-native';
import type {
  DirectEventHandler,
  Double,
} from 'react-native/Libraries/Types/CodegenTypes';
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

export interface SizeChangeEvent {
  width: Double;
  height: Double;
  duration?: Double;
}

export enum InlineMessageState {
  LoadingStarted = 'LoadingStarted',
  LoadingFinished = 'LoadingFinished',
  NoMessageToDisplay = 'NoMessageToDisplay',
}

export interface StateChangeEvent {
  state: string;
}

export interface NativeProps extends ViewProps {
  elementId?: string;
  onSizeChange: DirectEventHandler<SizeChangeEvent>;
  onStateChange?: DirectEventHandler<StateChangeEvent>;
}

export default codegenNativeComponent<NativeProps>(
  'InlineMessageNative'
) as HostComponent<NativeProps>;
