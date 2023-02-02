import { NativeEventEmitter, NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'customerio-reactnative' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';
/** Code by Rehan
 * Get CustomerioInAppMessaging native module
 */
 const CustomerIOInAppEventListener = NativeModules.CustomerioInAppMessaging
 ? NativeModules.CustomerioInAppMessaging
 : new Proxy(
   {},
   {
     get() {
       throw new Error(LINKING_ERROR);
     },
   }
 );
