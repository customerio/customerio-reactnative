import { NativeEventEmitter, NativeModules } from 'react-native';


/** Code by Rehan
 * Get CustomerIOInAppEventListener native module
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
