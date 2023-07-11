import React, { useEffect, useState } from 'react';
import {
  Alert,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import PushNotification from 'react-native-push-notification';
import Env from '../env';
import StorageManager from '../manager/StorageManager';
import SDKConfigurations from '../sdk/SDKConfigurations';
import { useThemeContext } from '../theme';
import { SDKConstants } from '../util/Constants';

const SettingsScreen = ({ navigation }) => {
  const theme = useThemeContext();

  const styles = StyleSheet.create({
    container: theme.styles.container,
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
      ...theme.styles.text,
      fontSize: 18,
      fontWeight: 'bold',
      marginBottom: 12,
    },
    inputRow: {
      flexDirection: 'row',
      alignItems: 'center',
    },
    inputLabel: {
      ...theme.styles.text,
      marginRight: 16,
    },
    input: {
      ...theme.styles.input,
      flex: 1,
    },
    switchRow: {
      flexDirection: 'row',
      alignItems: 'center',
      marginBottom: 16,
    },
    switchLabel: {
      ...theme.styles.text,
      flex: 1,
      marginRight: 8,
      textAlign: 'left',
    },
    switch: {},
    buttonContainer: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center',
      marginTop: 24,
    },
    saveButton: {
      ...theme.styles.filledButton,
      width: 320,
    },
    saveButtonText: {
      ...theme.styles.filledButtonText,
      textTransform: 'uppercase',
    },
    restoreDefaultsButton: {
      ...theme.styles.translucentButton,
      marginTop: 16,
      width: 320,
    },
    restoreDefaultsButtonText: theme.styles.translucentButtonText,
    note: {
      ...theme.styles.text,
      marginTop: 8,
      fontSize: 12,
      color: 'gray',
      textAlign: 'center',
    },
  });

  const sdkConfigurationsDefault = SDKConfigurations.createDefault();
  const storageManager = new StorageManager();

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
    const config = await storageManager.loadSDKConfigurations();

    setTrackUrl(config?.trackingUrl ?? sdkConfigurationsDefault.trackingUrl);
    setSiteId(config?.siteId ?? sdkConfigurationsDefault.siteId);
    setApiKey(config?.apiKey ?? sdkConfigurationsDefault.apiKey);
    setBQSecondsDelay(
      (
        config?.bqSecondsDelay ?? sdkConfigurationsDefault.bqSecondsDelay
      ).toString()
    );
    setBQMinNumberOfTasks(
      (
        config?.bqMinNumberOfTasks ??
        sdkConfigurationsDefault.bqMinNumberOfTasks
      ).toString()
    );
    setTrackScreensEnabled(
      config?.trackScreens ?? sdkConfigurationsDefault.trackScreens
    );
    setTrackDeviceAttributesEnabled(
      config?.trackDeviceAttributes ??
        sdkConfigurationsDefault.trackDeviceAttributes
    );
    setDebugModeEnabled(
      config?.debugMode ?? sdkConfigurationsDefault.debugMode
    );
  };

  PushNotification.configure({
    onRegister: function (token) {
      setDeviceToken(token.token);
    },
  });

  const handleRestoreDefaultsPress = async () => {
    return saveConfigurations(sdkConfigurationsDefault);
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
      Alert.alert(
        'Error',
        message,
        [
          {
            text: 'OK',
            // eslint-disable-next-line prettier/prettier
            onPress: () => { },
          },
        ],
        {
          cancelable: true,
        }
      );
      return false;
    }
    return true;
  };

  const handleSavePress = () => {
    if (!isFormValid()) {
      return;
    }

    const config = new SDKConfigurations();
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
    return storageManager
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
              placeholder={SDKConstants.TRACK_URL}
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
              placeholder={Env.siteId}
            />
          </View>
          <View style={styles.inputRow}>
            <Text style={styles.inputLabel}>API Key</Text>
            <TextInput
              style={styles.input}
              onChangeText={(text) => setApiKey(text)}
              value={apiKey}
              placeholder={Env.apiKey}
            />
          </View>
        </View>
        <View style={styles.section}>
          <View style={styles.inputRow}>
            <Text style={styles.inputLabel}>backgroundQueueSecondsDelay</Text>
            <TextInput
              style={styles.input}
              value={bqSecondsDelay ?? ''}
              placeholder={SDKConstants.BQ_SECONDS_DELAY.toString()}
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
              placeholder={SDKConstants.BQ_MIN_NUMBER_OF_TASKS.toString()}
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

export default SettingsScreen;
