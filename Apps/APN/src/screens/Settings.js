import { HeaderBackButton } from '@react-navigation/elements';
import { useFocusEffect } from '@react-navigation/native';
import React, {
  useCallback,
  useEffect,
  useLayoutEffect,
  useState,
} from 'react';
import {
  BackHandler,
  Clipboard,
  ScrollView,
  StyleSheet,
  View,
} from 'react-native';
import { FilledButton, TextButton } from '../components/Button';
import { SwitchField } from '../components/SwitchField';
import { Caption, Text } from '../components/Text';
import { TextField } from '../components/TextField';
import * as Colors from '../constants/Colors';
import * as Fonts from '../constants/Fonts';
import * as Sizes from '../constants/Sizes';
import CustomerIoSDKConfig from '../data/sdk/CustomerIoSDKConfig';
import { useCustomerIoSdkContext } from '../state/customerIoSdkState';
import { useUserStateContext } from '../state/userState';
import { resetRoute } from '../utils/navigation';
import Prompts from '../utils/prompts';

const Settings = ({ navigation, route }) => {
  const { params } = route;
  const initialSiteId = params.site_id;
  const initialApiKey = params.api_key;
  const { config: initialConfig, onSdkConfigStateChanged } =
    useCustomerIoSdkContext();
  const { user } = useUserStateContext();
  const defaultConfig = CustomerIoSDKConfig.createDefault();

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

  const handleOnBackPress = useCallback(() => {
    if (!navigation.canGoBack()) {
      resetRoute(navigation, user);
      return true;
    }

    return false;
  }, [navigation, user]);

  useLayoutEffect(() => {
    if (!navigation.canGoBack()) {
      navigation.setOptions({
        headerLeft: (props) => (
          <HeaderBackButton
            {...props}
            style={styles.backButton}
            onPress={() => handleOnBackPress()}
          />
        ),
      });
    }
  }, [handleOnBackPress, navigation]);

  useFocusEffect(
    useCallback(() => {
      const subscription = BackHandler.addEventListener(
        'hardwareBackPress',
        handleOnBackPress
      );

      return () => subscription.remove();
    }, [handleOnBackPress])
  );

  useEffect(() => {
    setTrackUrl(initialConfig.trackingUrl);
    setSiteId(initialSiteId ?? initialConfig.siteId);
    setApiKey(initialApiKey ?? initialConfig.apiKey);
    setBQSecondsDelay(initialConfig.bqSecondsDelay.toString());
    setBQMinNumberOfTasks(initialConfig.bqMinNumberOfTasks.toString());
    setTrackScreensEnabled(initialConfig.trackScreens);
    setTrackDeviceAttributesEnabled(initialConfig.trackDeviceAttributes);
    setDebugModeEnabled(initialConfig.debugMode);
  }, [initialApiKey, initialConfig, initialSiteId]);

  const handleRestoreDefaultsPress = async () => {
    saveConfigurations(defaultConfig);
  };

  const isTrackingURLValid = (value) => {
    const url = value.trim();

    // Empty text is not considered valid.
    if (url.length === 0) {
      return false;
    }

    // Regex pattern to match URLs with http/https schemes, non-empty hosts, and end with a forward slash.
    const urlRegex = /^(https?:\/\/)?([\w\d.-]+)(:\d+)?(\/.*)?$/;
    const matches = url.match(urlRegex);
    if (!matches) {
      return false;
    }

    const scheme = matches[1] || '';
    const host = matches[2] || '';
    const path = matches[4] || '';

    return (
      (scheme === 'http://' || scheme === 'https://') &&
      host.length > 0 &&
      path.endsWith('/')
    );
  };

  const toIntOrNull = (value) => {
    let number = parseInt(value, 10);
    return isNaN(number) ? null : number;
  };

  const toFloatOrNull = (value) => {
    let number = parseFloat(value);
    return isNaN(number) ? null : number;
  };

  const isFormValid = () => {
    let message;
    let blankFieldMessageBuilder = (fieldName) => {
      return `${fieldName} cannot be blank`;
    };
    let outOfBoundsValueMessageBuilder = (fieldName, minValue) => {
      return `${fieldName} must be greater than or equal to ${minValue}`;
    };

    const bqSecondsDelayValue = toFloatOrNull(bqSecondsDelay);
    const bqMinNumberOfTasksValue = toIntOrNull(bqMinNumberOfTasks);

    if (!isTrackingURLValid(trackUrl)) {
      message = 'Please enter formatted url e.g. https://tracking.cio/';
    } else if (!siteId) {
      message = blankFieldMessageBuilder('Site Id');
    } else if (!apiKey) {
      message = blankFieldMessageBuilder('API Key');
    } else if (!bqSecondsDelay) {
      message = blankFieldMessageBuilder('backgroundQueueSecondsDelay');
    } else if (bqSecondsDelayValue === null || bqSecondsDelayValue < 1) {
      message = outOfBoundsValueMessageBuilder(
        'backgroundQueueSecondsDelay',
        1
      );
    } else if (!bqMinNumberOfTasks) {
      message = blankFieldMessageBuilder('backgroundQueueMinNumberOfTasks');
    } else if (
      bqMinNumberOfTasksValue === null ||
      bqMinNumberOfTasksValue < 1
    ) {
      message = outOfBoundsValueMessageBuilder(
        'backgroundQueueMinNumberOfTasks',
        1
      );
    }

    if (message) {
      Prompts.showAlert({
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
    config.bqSecondsDelay = toFloatOrNull(bqSecondsDelay);
    config.bqMinNumberOfTasks = toIntOrNull(bqMinNumberOfTasks);
    config.trackScreens = isTrackScreensEnabled;
    config.trackDeviceAttributes = isTrackDeviceAttributesEnabled;
    config.debugMode = isDebugModeEnabled;
    saveConfigurations(config);
  };

  const saveConfigurations = async (config) => {
    await onSdkConfigStateChanged(config);
    navigation.goBack();
  };

  const copyToDeviceClipboard = async () => {
    Clipboard.setString(deviceToken);
    Prompts.showSnackbar({ text: 'Device token copied to clipboard' });
  };

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        <View style={styles.section}>
          <TextField
            style={styles.textInputContainer}
            label="Device Token"
            value={deviceToken}
            editable={false}
            leadingIconImageSource={require('../../assets/images/paper.png')}
            onLeadingIconPress={() => copyToDeviceClipboard()}
          />
          <TextField
            style={styles.textInputContainer}
            label="CIO Track URL"
            value={trackUrl}
            onChangeText={(text) => setTrackUrl(text)}
          />
        </View>
        <View style={styles.section}>
          <TextField
            style={styles.textInputContainer}
            label="Site Id"
            value={siteId}
            onChangeText={(text) => setSiteId(text)}
          />
          <TextField
            style={styles.textInputContainer}
            label="API Key"
            value={apiKey}
            onChangeText={(text) => setApiKey(text)}
          />
        </View>
        <View style={styles.section}>
          <TextField
            style={styles.textInputContainer}
            label="backgroundQueueSecondsDelay"
            value={bqSecondsDelay ?? ''}
            onChangeText={(text) => {
              let value = toFloatOrNull(text);
              return setBQSecondsDelay(value === null ? undefined : text);
            }}
          />
          <TextField
            style={styles.textInputContainer}
            label="backgroundQueueMinNumberOfTasks"
            value={bqMinNumberOfTasks ?? ''}
            onChangeText={(text) => {
              let value = toIntOrNull(text, 10);
              return setBQMinNumberOfTasks(value === null ? undefined : text);
            }}
          />
        </View>
        <View style={styles.section}>
          <Text style={styles.sectionLabel}>Features</Text>
          <SwitchField
            style={styles.switchRow}
            label="Track Screens"
            onValueChange={() => setTrackScreensEnabled(!isTrackScreensEnabled)}
            value={isTrackScreensEnabled}
          />
          <SwitchField
            style={styles.switchRow}
            label="Track Device Attributes"
            onValueChange={() =>
              setTrackDeviceAttributesEnabled(!isTrackDeviceAttributesEnabled)
            }
            value={isTrackDeviceAttributesEnabled}
          />
          <SwitchField
            style={styles.switchRow}
            label="Debug Mode"
            onValueChange={() => setDebugModeEnabled(!isDebugModeEnabled)}
            value={isDebugModeEnabled}
          />
        </View>
        <View style={styles.buttonContainer}>
          <FilledButton
            style={styles.saveButton}
            onPress={handleSavePress}
            text="Save"
            textStyle={styles.saveButtonText}
          />
          <TextButton
            style={styles.restoreDefaultsButton}
            onPress={handleRestoreDefaultsPress}
            text="Restore Defaults"
          />
          <Caption style={styles.note}>
            Note: You must restart the app to apply these settings
          </Caption>
        </View>
      </ScrollView>
    </View>
  );
};
const styles = StyleSheet.create({
  backButton: {
    marginLeft: Sizes.BACK_BUTTON_MARGIN_LEFT,
    marginRight: Sizes.BACK_BUTTON_MARGIN_RIGHT,
  },
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
    alignSelf: 'flex-start',
    fontSize: 16,
    fontWeight: Fonts.FONT_WEIGHT_BOLD,
    marginBottom: 16,
  },
  textInputContainer: {
    marginTop: 8,
  },
  switchRow: {
    marginBottom: 16,
  },
  buttonContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  saveButton: {
    marginTop: 8,
  },
  saveButtonText: {
    textTransform: 'uppercase',
  },
  restoreDefaultsButton: {
    marginTop: 16,
    width: Sizes.BUTTON_MAX_WIDTH,
  },
  note: {
    marginTop: 8,
  },
});

export default Settings;
