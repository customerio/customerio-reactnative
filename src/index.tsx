/**
 * This is react native package for Customer.io
 * Package name : customerio-reactnative
 */

import { CustomerioConfig, CustomerIOEnv } from './CustomerioConfig';
import { CioLogLevel, Region } from './CustomerioEnum';
import {
  CustomerIOInAppMessaging,
  InAppMessageEventType,
  InAppMessageEvent,
} from './CustomerIOInAppMessaging';
import { CustomerIO } from './CustomerioTracking';

export {
  CustomerIO,
  CustomerIOInAppMessaging,
  InAppMessageEventType,
  InAppMessageEvent,
  Region,
  CustomerioConfig,
  CustomerIOEnv,
  CioLogLevel,
};

export * from './types';

export type GistViewApi = {};

import { requireNativeComponent } from 'react-native';
export const InlineView = requireNativeComponent('InlineView');

// const Camera = React.forwardRef((props: CameraProps, ref: any) => {
//   const nativeRef = React.useRef();

//   React.useImperativeHandle<any, CameraApi>(ref, () => ({
//     capture: async () => {
//       return await CKCameraManager.capture({});
//     },
//     requestDeviceCameraAuthorization: async () => {
//       return await CKCameraManager.checkDeviceCameraAuthorizationStatus();
//     },
//     checkDeviceCameraAuthorizationStatus: async () => {
//       return await CKCameraManager.checkDeviceCameraAuthorizationStatus();
//     },
//   }));

//   return <NativeCamera style={{ minWidth: 100, minHeight: 100 }} ref={nativeRef} {...props} />;
// });

// Camera.defaultProps = {
//   resetFocusTimeout: 0,
//   resetFocusWhenMotionDetected: true,
// };

// export default Camera;
