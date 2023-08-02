import { NavigationProp, ParamListBase } from '@react-navigation/native';
import { PushPermissionStatus } from 'customerio-reactnative';
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
import { ScreenName } from '../data/enums/Screen';
import {
  getPushPermissionStatus,
  requestPushNotificationsPermission,
  trackEvent,
} from '../services/CustomerIOService';
import { useUserStateContext } from '../state/userState';
import { generateRandomNumber } from '../utils/helpers';
import { navigateToScreen } from '../utils/navigation';
import Prompts from '../utils/prompts';

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

  const handlePushPermissionCheck = () => {
    getPushPermissionStatus().then((status: PushPermissionStatus) => {
      switch (status) {
        case PushPermissionStatus.Granted:
          Prompts.showAlert({
            title: pushPermissionAlertTitle,
            message: 'Push notifications are enabled on this device',
          });
          break;

        case PushPermissionStatus.Denied:
        case PushPermissionStatus.NotDetermined:
          requestPushPermission();
          break;
      }
    });
  };

  const requestPushPermission = () => {
    let options = { ios: { sound: true, badge: true } };

    requestPushNotificationsPermission(options)
      .then((status: PushPermissionStatus) => {
        switch (status) {
          case PushPermissionStatus.Granted:
            Prompts.showSnackbar({
              text: 'Push notifications are now enabled on this device',
            });
            break;

          case PushPermissionStatus.Denied:
          case PushPermissionStatus.NotDetermined:
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
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      .catch((error: any) => {
        Prompts.showAlert({
          title: pushPermissionAlertTitle,
          message: 'Unable to request permission. Please try again later.',
        });
      });
  };

  const handleSettingsPress = () => {
    navigateToScreen(navigation, ScreenName.SETTINGS);
  };

  const handleButtonClick = async (action: ActionItemType) => {
    switch (action) {
      case ActionItem.RANDOM_EVENT:
        sendRandomEvent();
        break;

      case ActionItem.SHOW_PUSH_PROMPT:
        handlePushPermissionCheck();
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

  return (
    <View style={styles.container}>
      <View style={styles.topBar}>
        <TouchableOpacity
          style={styles.settingsButton}
          onPress={handleSettingsPress}
          accessibilityLabel="Settings">
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
  targetScreen?: ScreenName;
}

const ActionItem: Record<string, ActionItemType> = {
  RANDOM_EVENT: {
    text: 'Send Random Event',
    contentDesc: 'Random Event Button',
  },
  CUSTOM_EVENT: {
    text: 'Send Custom Event',
    contentDesc: 'Custom Event Button',
    targetScreen: ScreenName.CUSTOM_EVENTS,
  },
  DEVICE_ATTRIBUTES: {
    text: 'Set Device Attribute',
    contentDesc: 'Device Attribute Button',
    targetScreen: ScreenName.DEVICE_ATTRIBUTES,
  },
  PROFILE_ATTRIBUTES: {
    text: 'Set Profile Attribute',
    contentDesc: 'Profile Attribute Button',
    targetScreen: ScreenName.PROFILE_ATTRIBUTES,
  },
  SHOW_PUSH_PROMPT: {
    text: 'Show Push Prompt',
    contentDesc: 'Show Push Prompt Button',
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
