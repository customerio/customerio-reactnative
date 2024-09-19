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
import Screen from '../data/enums/Screen';
import {
  getPushPermissionStatus,
  requestPushNotificationsPermission,
  trackEvent,
} from '../services/CustomerIOService';
import { useUserStateContext } from '../state/userState';
import { generateRandomNumber } from '../utils/helpers';
import { navigateToScreen } from '../utils/navigation';
import Prompts from '../utils/prompts';
import { Notifications } from 'react-native-notifications';
import { CustomerIO } from 'customerio-reactnative';

const pushPermissionAlertTitle = 'Push Permission';

const Dashboard = ({ navigation }) => {
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
        propertyName = null;
        propertyValue = null;
        break;
    }

    trackEvent(eventName, propertyName, propertyValue);
    Prompts.showSnackbar({ text: 'Event sent successfully' });
  };

  const handlePushPermissionCheck = () => {
    getPushPermissionStatus().then((status) => {
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
    });
  };

  const requestPushPermission = () => {
    let options = { ios: { sound: true, badge: true } };

    requestPushNotificationsPermission(options)
      .then((status) => {
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
      })
      .catch((error) => {
        Prompts.showAlert({
          title: pushPermissionAlertTitle,
          message: 'Unable to request permission. Please try again later.',
        });
      });
  };

  const handleSettingsPress = () => {
    navigateToScreen(navigation, Screen.SETTINGS);
  };

  const handleButtonClick = async (action) => {
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
        });
        break;

      case ActionItem.SIGN_OUT:
        onUserStateChanged(null);
        break;

      case ActionItem.CUSTOM_EVENT:
      case ActionItem.DEVICE_ATTRIBUTES:
      case ActionItem.PROFILE_ATTRIBUTES:
        navigateToScreen(navigation, action.targetScreen);
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
        `Non-Customer.io notification received in foreground: ${notification.title} : ${notification.body}`
      );

      completion({ alert: true, sound: true, badge: true });
    }
  );
  // Important to test that 3rd party SDK is able to receive a callback when a push notification is clicked for non-CIO sent pushes.
  Notifications.events().registerNotificationOpened(
    (notification: Notification, completion) => {
      console.log(
        `Non-Customer.io notification opened: ${notification.payload}`
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
          accessibilityLabel="Settings"
        >
          <Image
            source={require('../../assets/images/black-settings-button.png')}
            style={styles.settingsIcon}
          />
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.container}>
        <View style={styles.spaceTop} />

        <View style={styles.content}>
          <Text style={styles.email} contentDesc="Email ID Text">
            {user.email}
          </Text>
          <Text style={styles.title}>What would you like to test?</Text>
          {Object.values(ActionItem).map((action) => (
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

const ActionItem = {
  RANDOM_EVENT: {
    text: 'Send Random Event',
    contentDesc: 'Random Event Button',
    targetScreen: null,
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
    targetScreen: null,
  },
  SHOW_LOCAL_PUSH: {
    text: 'Show Local Push',
    contentDesc: 'Show Local Push Button',
    targetScreen: null,
  },
  SIGN_OUT: {
    text: 'Log Out',
    contentDesc: 'Log Out Button',
    targetScreen: null,
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
