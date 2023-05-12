import 'react-native-gesture-handler';
import { AppRegistry } from 'react-native';
import PushNotificationIOS from '@react-native-community/push-notification-ios';
import PushNotification from "react-native-push-notification";
import {name as appName} from './app.json';
import App from './App';


AppRegistry.registerComponent(appName, () => App);
