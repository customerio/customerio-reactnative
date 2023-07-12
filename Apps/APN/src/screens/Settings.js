import React, { useEffect, useState } from 'react';
import {
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import PushNotification from 'react-native-push-notification';
import * as Colors from '../constants/Colors';
import * as Fonts from '../constants/Fonts';
import * as Sizes from '../constants/Sizes';
import CustomerIoSDKConfig from '../data/sdk/CustomerIoSDKConfig';
import StorageService from '../services/StorageService';
import AlertUtils from '../utils/AlertUtils';

const Settings = ({ navigation }) => {
  const defaultConfig = CustomerIoSDKConfig.createDefault();
  const storageService = new StorageService();

  const [deviceToken, setDeviceToken] = useState('');
  const [trackUrl, setTrackUrl] = useState('');
  const [siteId, setSiteId] = useState('');
  const [apiKey, setApiKey] = useState('');
  const [bqSecondsDelay, setBQSecondsDelay] = useState(undefined);
  const [bqMinNumberOfTasks, setBQMinNumberOfTasks] = useState(undefined);
  const [isTrackScreensEnabled, setTrackScreensEnabled] = useState(false);
  const [isTrackDeviceAttributesEnabled, setTrackDeviceAttributesEnabled] =
    useState(false);
  const [isDebugModeEnabled, setDebugModeEnabled] = useState(false);

  useEffect(() => {
    loadConfigurationsFromStorage();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const loadConfigurationsFromStorage = async () => {
    const config = CustomerIoSDKConfig.applyDefaultForUndefined(
      await storageService.loadSDKConfigurations()
    );

    setTrackUrl(config.trackingUrl);
    setSiteId(config.siteId);
    setApiKey(config.apiKey);
    setBQSecondsDelay(config.bqSecondsDelay.toString());
    setBQMinNumberOfTasks(config.bqMinNumberOfTasks.toString());
    setTrackScreensEnabled(config.trackScreens);
    setTrackDeviceAttributesEnabled(config.trackDeviceAttributes);
    setDebugModeEnabled(config.debugMode);
  };

  PushNotification.configure({
    onRegister: function (token) {
      setDeviceToken(token.token);
    },
  });

  const handleRestoreDefaultsPress = async () => {
    return saveConfigurations(defaultConfig);
  };

  const isTrackingURLValid = (value) => {
    const url = value.trim();

    // Empty text is not considered valid.
    if (url.length === 0) {
      return false;
    }

    // Regex pattern to match URLs with http/https schemes and non-empty hosts.
    const urlPattern = /^(http|https):\/\/[^/\s]+\/$/;

    // Test if the URL matches the pattern.
    return urlPattern.test(url);
  };

  const isFormValid = () => {
    let message;
    let blankFieldMessageBuilder = (fieldName) => {
      return `${fieldName} cannot be blank`;
    };
    let outOfBoundsValueMessageBuilder = (fieldName, minValue) => {
      return `${fieldName} must be greater than or equal to ${minValue}`;
    };

    if (!isTrackingURLValid(trackUrl)) {
      message = 'Please enter formatted url e.g. https://tracking.cio/';
    } else if (!siteId) {
      message = blankFieldMessageBuilder('Site Id');
    } else if (!apiKey) {
      message = blankFieldMessageBuilder('API Key');
    } else if (!bqSecondsDelay) {
      message = blankFieldMessageBuilder('backgroundQueueSecondsDelay');
    } else if (isNaN(bqSecondsDelay) || bqSecondsDelay < 1) {
      message = outOfBoundsValueMessageBuilder(
        'backgroundQueueSecondsDelay',
        1
      );
    } else if (!bqMinNumberOfTasks) {
      message = blankFieldMessageBuilder('backgroundQueueMinNumberOfTasks');
    } else if (isNaN(bqMinNumberOfTasks) || bqMinNumberOfTasks < 1) {
      message = outOfBoundsValueMessageBuilder(
        'backgroundQueueMinNumberOfTasks',
        1
      );
    }

    if (message) {
      AlertUtils.showAlert({
        title: 'Error',
        message: message,
      });
      return false;
    }
    return true;
  };

  const handleSavePress = () => {
    if (!isFormValid()) {
      return;
    }

    const config = new CustomerIoSDKConfig();
    config.siteId = siteId;
    config.apiKey = apiKey;
    config.trackingUrl = trackUrl;
    config.bqSecondsDelay = bqSecondsDelay;
    config.bqMinNumberOfTasks = bqMinNumberOfTasks;
    config.trackScreens = isTrackScreensEnabled;
    config.trackDeviceAttributes = isTrackDeviceAttributesEnabled;
    config.debugMode = isDebugModeEnabled;
    return saveConfigurations(config);
  };

  const saveConfigurations = async (config) => {
    return storageService
      .saveSDKConfigurations(config)
      .then(() => navigation.goBack());
  };

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        <View style={styles.section}>
          <View style={styles.inputRow}>
            <Text style={styles.inputLabel}>Device Token</Text>
            <TextInput
              style={styles.input}
              value={deviceToken}
              placeholder="Fetching..."
              editable={false}
            />
          </View>
          <View style={styles.inputRow}>
            <Text style={styles.inputLabel}>CIO Track URL</Text>
            <TextInput
              style={styles.input}
              onChangeText={(text) => setTrackUrl(text)}
              value={trackUrl}
              placeholder={defaultConfig.trackingUrl}
            />
          </View>
        </View>
        <View style={styles.section}>
          <View style={styles.inputRow}>
            <Text style={styles.inputLabel}>Site Id</Text>
            <TextInput
              style={styles.input}
              onChangeText={(text) => setSiteId(text)}
              value={siteId}
              placeholder={defaultConfig.siteId}
            />
          </View>
          <View style={styles.inputRow}>
            <Text style={styles.inputLabel}>API Key</Text>
            <TextInput
              style={styles.input}
              onChangeText={(text) => setApiKey(text)}
              value={apiKey}
              placeholder={defaultConfig.apiKey}
            />
          </View>
        </View>
        <View style={styles.section}>
          <View style={styles.inputRow}>
            <Text style={styles.inputLabel}>backgroundQueueSecondsDelay</Text>
            <TextInput
              style={styles.input}
              value={bqSecondsDelay ?? ''}
              placeholder={defaultConfig.bqSecondsDelay.toString()}
              onChangeText={(text) => {
                let value = parseFloat(text);
                return setBQSecondsDelay(isNaN(value) ? undefined : value);
              }}
            />
          </View>
          <View style={styles.inputRow}>
            <Text style={styles.inputLabel}>
              backgroundQueueMinNumberOfTasks
            </Text>
            <TextInput
              style={styles.input}
              value={bqMinNumberOfTasks ?? ''}
              placeholder={defaultConfig.bqMinNumberOfTasks.toString()}
              onChangeText={(text) => {
                let value = parseInt(text, 10);
                return setBQMinNumberOfTasks(isNaN(value) ? undefined : value);
              }}
            />
          </View>
        </View>
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Features</Text>
          <View style={styles.switchRow}>
            <Text style={styles.switchLabel}>Track Screens</Text>
            <Switch
              style={styles.switch}
              onValueChange={() =>
                setTrackScreensEnabled(!isTrackScreensEnabled)
              }
              value={isTrackScreensEnabled}
            />
          </View>
          <View style={styles.switchRow}>
            <Text style={styles.switchLabel}>Track Device Attributes</Text>
            <Switch
              style={styles.switch}
              onValueChange={() =>
                setTrackDeviceAttributesEnabled(!isTrackDeviceAttributesEnabled)
              }
              value={isTrackDeviceAttributesEnabled}
            />
          </View>
          <View style={styles.switchRow}>
            <Text style={styles.switchLabel}>Debug Mode</Text>
            <Switch
              style={styles.switch}
              onValueChange={() => setDebugModeEnabled(!isDebugModeEnabled)}
              value={isDebugModeEnabled}
            />
          </View>
        </View>
        <View style={styles.buttonContainer}>
          <TouchableOpacity onPress={handleSavePress} style={styles.saveButton}>
            <Text style={styles.saveButtonText}>Save</Text>
          </TouchableOpacity>
          <TouchableOpacity
            onPress={handleRestoreDefaultsPress}
            style={styles.restoreDefaultsButton}
          >
            <Text style={styles.restoreDefaultsButtonText}>
              Restore Defaults
            </Text>
          </TouchableOpacity>
          <Text style={styles.note}>
            Note: You must restart the app to apply these settings
          </Text>
        </View>
      </ScrollView>
    </View>
  );
};
const styles = StyleSheet.create({
  container: {
    backgroundColor: Colors.CONTAINER_BACKGROUND_COLOR,
    flex: 1,
  },
  content: {
    flexGrow: 1,
    paddingHorizontal: 16,
    paddingTop: 8,
    paddingBottom: 16,
  },
  section: {
    marginBottom: 24,
  },
  sectionLabel: {
    color: Colors.TEXT_COLOR_PRIMARY,
    fontFamily: Fonts.FONT_FAMILY_REGULAR,
    fontSize: 16,
    fontWeight: Fonts.FONT_WEIGHT_BOLD,
    marginBottom: 12,
  },
  inputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 8,
  },
  inputLabel: {
    color: Colors.TEXT_COLOR_PRIMARY,
    fontFamily: Fonts.FONT_FAMILY_REGULAR,
    fontSize: 14,
    fontWeight: Fonts.FONT_WEIGHT_REGULAR,
    marginRight: 16,
  },
  input: {
    borderBottomWidth: Sizes.INPUT_FIELD_BORDER_WIDTH_BOTTOM,
    borderColor: Colors.INPUT_FIELD_BORDER_COLOR,
    borderRadius: Sizes.INPUT_FIELD_BORDER_RADIUS,
    flex: 1,
    height: Sizes.INPUT_FIELD_HEIGHT,
    maxWidth: Sizes.INPUT_FIELD_MAX_WIDTH,
    paddingHorizontal: Sizes.INPUT_FIELD_PADDING_HORIZONTAL,
  },
  switchRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
  },
  switchLabel: {
    color: Colors.TEXT_COLOR_PRIMARY,
    flex: 1,
    fontFamily: Fonts.FONT_FAMILY_REGULAR,
    fontSize: 14,
    fontWeight: Fonts.FONT_WEIGHT_REGULAR,
    marginRight: 8,
    textAlign: 'left',
  },
  switch: {},
  buttonContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 8,
  },
  saveButton: {
    backgroundColor: Colors.PRIMARY_COLOR,
    borderRadius: Sizes.BUTTON_BORDER_RADIUS,
    paddingHorizontal: Sizes.BUTTON_PADDING_HORIZONTAL,
    paddingVertical: Sizes.BUTTON_PADDING_VERTICAL,
    maxWidth: Sizes.BUTTON_MAX_WIDTH,
    width: Sizes.BUTTON_MAX_WIDTH,
  },
  saveButtonText: {
    color: Colors.TEXT_COLOR_ON_PRIMARY,
    fontFamily: Fonts.FONT_FAMILY_REGULAR,
    fontSize: Fonts.FONT_SIZE_BUTTON_DEFAULT,
    fontWeight: Fonts.FONT_FAMILY_BOLD,
    textAlign: 'center',
    textTransform: 'uppercase',
  },
  restoreDefaultsButton: {
    borderRadius: Sizes.BUTTON_BORDER_RADIUS,
    paddingHorizontal: Sizes.BUTTON_PADDING_HORIZONTAL,
    paddingVertical: Sizes.BUTTON_PADDING_VERTICAL,
    marginTop: 16,
    maxWidth: Sizes.BUTTON_MAX_WIDTH,
    width: Sizes.BUTTON_MAX_WIDTH,
  },
  restoreDefaultsButtonText: {
    color: Colors.SECONDARY_COLOR,
    fontFamily: Fonts.FONT_FAMILY_REGULAR,
    fontSize: Fonts.FONT_SIZE_BUTTON_DEFAULT,
    fontWeight: Fonts.FONT_FAMILY_BOLD,
    textAlign: 'center',
  },
  note: {
    color: Colors.TEXT_COLOR_TERTIARY,
    fontFamily: Fonts.FONT_FAMILY_REGULAR,
    fontSize: 12,
    fontWeight: Fonts.FONT_WEIGHT_REGULAR,
    marginTop: 8,
    textAlign: 'center',
  },
});

export default Settings;
