import {AppRegistry} from 'react-native';
import {CustomerIO} from 'customerio-reactnative';
import App from './src/App';

// Before registerComponent: on Android, a silent push can start the app in the background and run
// this file without mounting App.
CustomerIO.pushMessaging.setBackgroundPushHandler(async push => {
  console.log('[SilentPush] received', JSON.stringify(push));
});

AppRegistry.registerComponent('React Native FCM', () => App);
AppRegistry.registerComponent('React Native APN', () => App);
AppRegistry.registerComponent('React Native Android', () => App);
