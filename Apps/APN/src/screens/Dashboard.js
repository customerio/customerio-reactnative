import { PushPermissionStatus } from 'customerio-reactnative';
import React from 'react';
import {
  Image,
  Linking,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { ScrollView } from 'react-native-gesture-handler';
import BuildInfoText from '../components/BuildInfoText';
import * as Colors from '../constants/Colors';
import * as Fonts from '../constants/Fonts';
import * as Sizes from '../constants/Sizes';
import Screen from '../data/enums/Screen';
import CustomerIOService from '../services/CustomerIOService';
import StorageService from '../services/StorageService';
import AlertUtils from '../utils/AlertUtils';
import ScreenUtils from '../utils/ScreenUtils';

const pushPermissionAlertTitle = 'Push Permission';

const Dashboard = ({ navigation, route }) => {
  const { user } = route.params;

  const handlePushPermissionCheck = () => {
    CustomerIOService.getPushPermissionStatus().then((status) => {
      switch (status) {
        case PushPermissionStatus.Granted:
          AlertUtils.showAlert({
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

    CustomerIOService.showPromptForPushNotifications(options)
      .then((status) => {
        switch (status) {
          case PushPermissionStatus.Granted:
            AlertUtils.showAlert({
              title: pushPermissionAlertTitle,
              message: 'Push notifications are now enabled on this device',
            });
            break;

          case PushPermissionStatus.Denied:
          case PushPermissionStatus.NotDetermined:
            AlertUtils.showAlert({
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
        AlertUtils.showAlert({
          title: pushPermissionAlertTitle,
          message: 'Unable to request permission. Please try again later.',
        });
      });
  };

  const handleSettingsPress = () => {
    ScreenUtils.navigateToScreen(navigation, Screen.SETTINGS);
  };

  const handleButtonClick = async (action) => {
    switch (action) {
      case ActionItem.RANDOM_EVENT:
        break;

      case ActionItem.SHOW_PUSH_PROMPT:
        handlePushPermissionCheck();
        break;

      case ActionItem.SIGN_OUT:
        const storageService = new StorageService();
        await storageService.clearUser();
        CustomerIOService.clearUserIdentify();
        ScreenUtils.navigateToScreen(navigation, Screen.LOGIN);
        break;

      case ActionItem.CUSTOM_EVENT:
      case ActionItem.DEVICE_ATTRIBUTES:
      case ActionItem.PROFILE_ATTRIBUTES:
        ScreenUtils.navigateToScreen(navigation, action.targetScreen);
        break;
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.topBar}>
        <TouchableOpacity
          style={styles.settingsButton}
          onPress={handleSettingsPress}
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
          <Text style={styles.email}>{user.email}</Text>
          <Text style={styles.title}>What would you like to test?</Text>
          {Object.values(ActionItem).map((action) => (
            <TouchableOpacity
              key={action.text}
              style={styles.actionButton}
              onPress={() => handleButtonClick(action)}
            >
              <Text style={styles.actionButtonText}>{action.text}</Text>
            </TouchableOpacity>
          ))}
        </View>

        <View style={styles.spaceBottom} />

        <BuildInfoText style={styles.footerText} />
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
    alignSelf: 'center',
    color: Colors.TEXT_COLOR_PRIMARY,
    fontFamily: Fonts.FONT_FAMILY_REGULAR,
    fontSize: 20,
    fontWeight: Colors.FONT_WEIGHT_REGULAR,
    marginBottom: 16,
    marginTop: 16,
  },
  title: {
    alignSelf: 'center',
    color: Colors.TEXT_COLOR_PRIMARY,
    fontFamily: Fonts.FONT_FAMILY_REGULAR,
    fontSize: 20,
    fontWeight: Colors.FONT_WEIGHT_REGULAR,
    marginBottom: 16,
  },
  actionButton: {
    backgroundColor: Colors.PRIMARY_COLOR,
    borderRadius: Sizes.BUTTON_BORDER_RADIUS,
    paddingHorizontal: Sizes.BUTTON_PADDING_HORIZONTAL,
    paddingVertical: Sizes.BUTTON_PADDING_VERTICAL,
    marginTop: 16,
    maxWidth: Sizes.BUTTON_MAX_WIDTH,
    width: '80%',
  },
  actionButtonText: {
    color: Colors.TEXT_COLOR_ON_PRIMARY,
    fontFamily: Fonts.FONT_FAMILY_REGULAR,
    fontWeight: Fonts.FONT_FAMILY_BOLD,
    textAlign: 'center',
  },
  footer: {
    fontSize: 14,
    textAlign: 'center',
  },
});

export default Dashboard;
