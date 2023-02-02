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

const eventsList = [
    "messageShown",
    "messageDismissed",
    "errorWithMessage",
    "messageActionTaken"
  ]

class CustomerioInAppEventsManager {

  static registerInAppEventListeners(handler: (eventName: string, data: any) => void,
  ): void  {
    const eventEmitter = new NativeEventEmitter(CustomerIOInAppEventListener);
    for (let i = 0; i < eventsList.length; i++) {
      let eventName = eventsList[i];
      // Remove existing listeners to avoid duplicate listeners for same event
      eventEmitter.removeAllListeners(eventName)

      // Add listeners
      eventEmitter.addListener(eventName, (message: any) => {
        handler(eventName, message)
      });
    }
  } 
}

export { CustomerioInAppEventsManager };
