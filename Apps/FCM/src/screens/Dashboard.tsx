import { NavigationProp, ParamListBase } from '@react-navigation/native';
import { CioPushPermissionStatus } from 'customerio-reactnative';
import React from 'react';
import {
  Image,
  Linking,
  StyleSheet,
  TouchableOpacity,
  View,
} from 'react-native';
import { ScrollView } from 'react-native-gesture-handler';
import BuildInfoText from '../components/BuildInfoText';
import { FilledButton } from '../components/Button';
import { Text } from '../components/Text';
import * as Colors from '../constants/Colors';
import * as Sizes from '../constants/Sizes';
import { Screen } from '../data/enums/Screen';
import {
  getPushPermissionStatus,
  requestPushNotificationsPermission,
  trackEvent,
} from '../services/CustomerIOService';
import { useUserStateContext } from '../state/userState';
import { generateRandomNumber } from '../utils/helpers';
import { navigateToScreen } from '../utils/navigation';
import Prompts from '../utils/prompts';
import { Notification, Notifications } from 'react-native-notifications';
import { CustomerIO } from 'customerio-reactnative';

const pushPermissionAlertTitle = 'Push Permission';

interface DashboardProps {
  navigation: NavigationProp<ParamListBase>;
}

const Dashboard: React.FC<DashboardProps> = ({ navigation }) => {
  const { onUserStateChanged, user } = useUserStateContext();

  const sendRandomEvent = () => {
    let randomNumber = generateRandomNumber({ max: 3 });
    let eventName;
    let propertyName;
    let propertyValue;

    switch (randomNumber) {
      case 3:
        const appointmentTime = new Date();
        appointmentTime.setDate(appointmentTime.getDate() + 7);

        eventName = 'appointmentScheduled';
        propertyName = 'appointmentTime';
        propertyValue = Math.round(appointmentTime.getTime() / 1000);
        break;

      case 2:
        eventName = 'movie_watched';
        propertyName = 'movie_name';
        propertyValue = 'The Incredibles';
        break;

      case 1:
      default:
        eventName = 'Order Purchased';
        propertyName = undefined;
        propertyValue = undefined;
        break;
    }

    trackEvent(eventName, propertyName, propertyValue);
    Prompts.showSnackbar({ text: 'Event sent successfully' });
  };

  const handlePushPermissionCheck = async () => {
    const status = await getPushPermissionStatus();
    switch (status) {
      case CioPushPermissionStatus.Granted:
        Prompts.showAlert({
          title: pushPermissionAlertTitle,
          message: 'Push notifications are enabled on this device',
        });
        break;
  
      case CioPushPermissionStatus.Denied:
      case CioPushPermissionStatus.NotDetermined:
        requestPushPermission();
        break;
    }
  };

  const requestPushPermission = async () => {
    let options = { ios: { sound: true, badge: true } };

    const status = await requestPushNotificationsPermission(options);
        switch (status) {
          case CioPushPermissionStatus.Granted:
            Prompts.showSnackbar({
              text: 'Push notifications are now enabled on this device',
            });
            break;

          case CioPushPermissionStatus.Denied:
          case CioPushPermissionStatus.NotDetermined:
            Prompts.showAlert({
              title: pushPermissionAlertTitle,
              message:
                'Push notifications are denied on this device. Please allow notification permission from settings to receive push on this device.',
              buttons: [
                {
                  text: 'OK',
                  // eslint-disable-next-line prettier/prettier
                  onPress: () => { },
                },
                {
                  text: 'Open Settings',
                  onPress: () => {
                    Linking.openSettings();
                  },
                },
              ],
            });
            break;
        }
  };

  const handleSettingsPress = () => {
    navigateToScreen(navigation, Screen.SETTINGS);
  };

  const handleButtonClick = async (action: ActionItemType) => {
    switch (action) {
      case ActionItem.RANDOM_EVENT:
        sendRandomEvent();
        break;

      case ActionItem.SHOW_PUSH_PROMPT:
        handlePushPermissionCheck();
        break;

        case ActionItem.SHOW_LOCAL_PUSH:
          // How we are able to test behavior of pushes sent by other SDKs, not CIO.
          // Have 3rd party SDK create a push. We expect the SDK is able to handle this push that it owns.
          Notifications.postLocalNotification({
            body: 'Try clicking on me. The SDK that sent this should also be able to handle it.',
            title: 'Local push not sent by Customer.io',
          } as Notification);
          break;

      case ActionItem.SIGN_OUT:
        await onUserStateChanged(undefined);
        break;

      case ActionItem.CUSTOM_EVENT:
      case ActionItem.DEVICE_ATTRIBUTES:
      case ActionItem.PROFILE_ATTRIBUTES:
        navigateToScreen(navigation, action.targetScreen!);
        break;
    }
  };

  // Setup 3rd party SDK, react-native-notifications
  // We install this SDK into sample app to make sure the CIO SDK behaves as expected when there is another SDK installed that handles push notifications.
  //
  // Important to test that 3rd party SDK is able to decide if a push is shown or not while app is in foreground for non-CIO sent pushes.
  Notifications.events().registerNotificationReceivedForeground(
    (notification: Notification, completion) => {
      console.log(
        `notification received in foreground: ${notification.title} : ${notification.body}`
      );

      CustomerIO.track('push should show app in foreground', {
        push: notification.payload
      });

      completion({ alert: true, sound: true, badge: true });
    }
  );
  // Important to test that 3rd party SDK is able to receive a callback when a push notification is clicked for non-CIO sent pushes.
  Notifications.events().registerNotificationOpened(
    (notification: Notification, completion) => {
      console.log(
        `notification opened: ${notification.payload}`
      );

      CustomerIO.track('push clicked', { push: notification.payload });

      completion();
    }
  );

  return (
    <View style={styles.container}>
      <View style={styles.topBar}>
        <TouchableOpacity
          style={styles.settingsButton}
          onPress={handleSettingsPress}
          accessibilityLabel="Settings">
          <Image
            source={require('../../assets/images/ic_settings.png')}
            style={styles.settingsIcon}
          />
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.container}>
        <View style={styles.spaceTop} />

        <View style={styles.content}>
          <Text style={styles.email} contentDesc="Email ID Text">
            {user?.email}
          </Text>
          <Text style={styles.title}>What would you like to test?</Text>
          {Object.values(ActionItem).map(action => (
            <FilledButton
              key={action.text}
              style={styles.actionButton}
              onPress={() => handleButtonClick(action)}
              text={action.text}
              contentDesc={action.contentDesc}
            />
          ))}
        </View>

        <View style={styles.spaceBottom} />

        <BuildInfoText />
      </ScrollView>
    </View>
  );
};

interface ActionItemType {
  text: string;
  contentDesc: string;
  targetScreen?: Screen;
}

const ActionItem: Record<string, ActionItemType> = {
  RANDOM_EVENT: {
    text: 'Send Random Event',
    contentDesc: 'Random Event Button',
  },
  CUSTOM_EVENT: {
    text: 'Send Custom Event',
    contentDesc: 'Custom Event Button',
    targetScreen: Screen.CUSTOM_EVENTS,
  },
  DEVICE_ATTRIBUTES: {
    text: 'Set Device Attribute',
    contentDesc: 'Device Attribute Button',
    targetScreen: Screen.DEVICE_ATTRIBUTES,
  },
  PROFILE_ATTRIBUTES: {
    text: 'Set Profile Attribute',
    contentDesc: 'Profile Attribute Button',
    targetScreen: Screen.PROFILE_ATTRIBUTES,
  },
  SHOW_PUSH_PROMPT: {
    text: 'Show Push Prompt',
    contentDesc: 'Show Push Prompt Button',
  },
  SHOW_LOCAL_PUSH: {
    text: 'Show Local Push',
    contentDesc: 'Show Local Push Button',
  },  
  SIGN_OUT: {
    text: 'Log Out',
    contentDesc: 'Log Out Button',
  },
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: Colors.CONTAINER_BACKGROUND_COLOR,
    flex: 1,
  },
  topBar: {
    alignItems: 'center',
    flexDirection: 'row',
    height: Sizes.TOP_BAR_HEIGHT,
    justifyContent: 'flex-end',
    paddingHorizontal: Sizes.TOP_BAR_PADDING_HORIZONTAL,
  },
  settingsButton: {
    padding: Sizes.IMAGE_BUTTON_PADDING,
  },
  settingsIcon: {
    width: Sizes.IMAGE_BUTTON_ICON_SIZE,
    height: Sizes.IMAGE_BUTTON_ICON_SIZE,
  },
  spaceTop: {
    flex: 1,
  },
  spaceBottom: {
    flex: 1,
  },
  content: {
    alignItems: 'center',
    padding: 10,
  },
  email: {
    fontSize: 16,
    marginBottom: 16,
    marginTop: 16,
  },
  title: {
    fontSize: 18,
    marginBottom: 16,
  },
  actionButton: {
    marginTop: 16,
  },
});

export default Dashboard;
