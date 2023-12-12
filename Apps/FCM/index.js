/**
 * @format
 */

import { AppRegistry } from 'react-native';
import App from './App';
import { name as appName } from './app.json';
import messaging from '@react-native-firebase/messaging';
import { CustomerIO } from 'customerio-reactnative';

// Setup 3rd party SDK, rn-firebase.
// We install this SDK into sample app to make sure the CIO SDK behaves as expected when there is another SDK installed that handles push notifications.
//
// Only called when app in background and user taps on notification
// Note: This function is required to exist here instead of inside of a Component like some other messaging() function calls.
messaging().onNotificationOpenedApp(remoteMessage => {
  console.log(
    `Non-Customer.io notification opened: ${remoteMessage.notification}`,
  );

  CustomerIO.track('push clicked', { push: remoteMessage });
});

AppRegistry.registerComponent(appName, () => App);
