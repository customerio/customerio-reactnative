import Clipboard from '@react-native-clipboard/clipboard';
import { HeaderBackButton } from '@react-navigation/elements';
import {
  NavigationProp,
  ParamListBase,
  RouteProp,
  useFocusEffect,
} from '@react-navigation/native';
import React, {
  useCallback,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
} from 'react';
import { BackHandler, ScrollView, StyleSheet, View } from 'react-native';
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
import { CustomerIO } from 'customerio-reactnative';

interface SettingsProps {
  navigation: NavigationProp<ParamListBase>;
  route: RouteProp<
    { params?: { site_id?: string; api_key?: string } },
    'params'
  >;
}

const Settings: React.FC<SettingsProps> = ({ navigation, route }) => {
  const { params } = route;
  const initialSiteId = params?.site_id;
  const initialApiKey = params?.api_key;
  const { config: initialConfig, onSdkConfigStateChanged } =
    useCustomerIoSdkContext();
  const { user } = useUserStateContext();
  const defaultConfig = CustomerIoSDKConfig.createDefault();

  // Will be used once we roll out feature for exposing device token
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [deviceToken, setDeviceToken] = useState('');
  const [trackUrl, setTrackUrl] = useState('');
  const [siteId, setSiteId] = useState('');
  const [apiKey, setApiKey] = useState('');
  const [bqSecondsDelay, setBQSecondsDelay] = useState<string | undefined>(
    undefined,
  );
  const [bqMinNumberOfTasks, setBQMinNumberOfTasks] = useState<
    string | undefined
  >(undefined);
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
      setNavigationOptions(navigation, handleOnBackPress);
    }
  }, [handleOnBackPress, navigation]);

  useFocusEffect(
    useCallback(() => {
      const subscription = BackHandler.addEventListener(
        'hardwareBackPress',
        handleOnBackPress,
      );

      return () => subscription.remove();
    }, [handleOnBackPress]),
  );

  useEffect(() => {
    let setValueIfPresent: <T>(
      value: T | undefined,
      setter: (value: T) => void,
    ) => void = (value, setter) => {
      if (value) {
        setter(value);
      }
    };

    CustomerIO.pushMessaging()
      .getRegisteredDeviceToken()
      .then((token) => {
        setDeviceToken(token);
      })
      .catch((error) => {
        console.log(error);
      });
    setValueIfPresent(initialConfig?.trackingUrl, setTrackUrl);
    setValueIfPresent(initialSiteId ?? initialConfig?.siteId, setSiteId);
    setValueIfPresent(initialApiKey ?? initialConfig?.apiKey, setApiKey);
    setValueIfPresent(
      initialConfig?.bqSecondsDelay?.toString(),
      setBQSecondsDelay,
    );
    setValueIfPresent(
      initialConfig?.bqMinNumberOfTasks?.toString(),
      setBQMinNumberOfTasks,
    );
    setValueIfPresent(initialConfig?.trackScreens, setTrackScreensEnabled);
    setValueIfPresent(
      initialConfig?.trackDeviceAttributes,
      setTrackDeviceAttributesEnabled,
    );
    setValueIfPresent(initialConfig?.debugMode, setDebugModeEnabled);
  }, [initialApiKey, initialConfig, initialSiteId]);

  const handleRestoreDefaultsPress = async () => {
    saveConfigurations(defaultConfig);
  };

  const isTrackingURLValid = (value: string) => {
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

  const toIntOrUndefined = (value: string | undefined): number | undefined => {
    return value !== undefined ? parseInt(value, 10) || undefined : undefined;
  };

  const toFloatOrUndefined = (
    value: string | undefined,
  ): number | undefined => {
    return value !== undefined ? parseFloat(value) || undefined : undefined;
  };

  const isFormValid = () => {
    let message;
    let blankFieldMessageBuilder = (fieldName: string) => {
      return `${fieldName} cannot be blank`;
    };
    let outOfBoundsValueMessageBuilder = (fieldName: string, minValue: any) => {
      return `${fieldName} must be greater than or equal to ${minValue}`;
    };

    const bqSecondsDelayValue = toFloatOrUndefined(bqSecondsDelay);
    const bqMinNumberOfTasksValue = toIntOrUndefined(bqMinNumberOfTasks);

    if (!isTrackingURLValid(trackUrl)) {
      message = 'Please enter formatted url e.g. https://tracking.cio/';
    } else if (!siteId) {
      message = blankFieldMessageBuilder('Site Id');
    } else if (!apiKey) {
      message = blankFieldMessageBuilder('API Key');
    } else if (!bqSecondsDelay) {
      message = blankFieldMessageBuilder('backgroundQueueSecondsDelay');
    } else if (!bqSecondsDelayValue || bqSecondsDelayValue < 1) {
      message = outOfBoundsValueMessageBuilder(
        'backgroundQueueSecondsDelay',
        1,
      );
    } else if (!bqMinNumberOfTasks) {
      message = blankFieldMessageBuilder('backgroundQueueMinNumberOfTasks');
    } else if (!bqMinNumberOfTasksValue || bqMinNumberOfTasksValue < 1) {
      message = outOfBoundsValueMessageBuilder(
        'backgroundQueueMinNumberOfTasks',
        1,
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
    config.bqSecondsDelay = toFloatOrUndefined(bqSecondsDelay);
    config.bqMinNumberOfTasks = toIntOrUndefined(bqMinNumberOfTasks);
    config.trackScreens = isTrackScreensEnabled;
    config.trackDeviceAttributes = isTrackDeviceAttributesEnabled;
    config.debugMode = isDebugModeEnabled;
    saveConfigurations(config);
  };

  const saveConfigurations = async (config: CustomerIoSDKConfig) => {
    await onSdkConfigStateChanged(config);
    navigation.goBack();
  };

  const copyToDeviceClipboard = async () => {
    Clipboard.setString(deviceToken);
    Prompts.showSnackbar({ text: 'Device token copied to clipboard' });
  };

  const trackUrlRef = useRef();
  const siteIdRef = useRef();
  const apiKeyRef = useRef();
  const bqSecondsDelayRef = useRef();
  const bqMinNumberOfTasksRef = useRef();

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        <View style={styles.section}>
          <TextField
            style={styles.textInputContainer}
            label="Device Token"
            value={deviceToken}
            contentDesc="Device Token Input"
            editable={false}
            leadingIconImageSource={require('../../assets/images/ic_copy.png')}
            onLeadingIconPress={() => copyToDeviceClipboard()}
          />
          <TextField
            style={styles.textInputContainer}
            label="CIO Track URL"
            value={trackUrl}
            contentDesc="Track URL Input"
            onChangeText={text => setTrackUrl(text)}
            textInputRef={trackUrlRef}
            getNextTextInput={() => ({ ref: siteIdRef, value: siteId })}
            textInputProps={{
              autoCapitalize: 'none',
              keyboardType: 'url',
            }}
          />
        </View>
        <View style={styles.section}>
          <TextField
            style={styles.textInputContainer}
            label="Site Id"
            value={siteId}
            contentDesc="Site ID Input"
            onChangeText={text => setSiteId(text)}
            textInputRef={siteIdRef}
            getNextTextInput={() => ({ ref: apiKeyRef, value: apiKey })}
            textInputProps={{
              autoCapitalize: 'none',
              keyboardType: 'default',
            }}
          />
          <TextField
            style={styles.textInputContainer}
            label="API Key"
            value={apiKey}
            contentDesc="API Key Input"
            onChangeText={text => setApiKey(text)}
            textInputRef={apiKeyRef}
            getNextTextInput={() => ({
              ref: bqSecondsDelayRef,
              value: bqSecondsDelay,
            })}
            textInputProps={{
              autoCapitalize: 'none',
              keyboardType: 'default',
            }}
          />
        </View>
        <View style={styles.section}>
          <TextField
            style={styles.textInputContainer}
            label="backgroundQueueSecondsDelay"
            value={bqSecondsDelay ?? ''}
            contentDesc="BQ Seconds Delay Input"
            onChangeText={text => {
              let value = toFloatOrUndefined(text);
              return setBQSecondsDelay(value ? text : undefined);
            }}
            textInputRef={bqSecondsDelayRef}
            getNextTextInput={() => ({
              ref: bqMinNumberOfTasksRef,
              value: bqMinNumberOfTasks,
            })}
            textInputProps={{
              autoCapitalize: 'none',
              keyboardType: 'decimal-pad',
            }}
          />
          <TextField
            style={styles.textInputContainer}
            label="backgroundQueueMinNumberOfTasks"
            value={bqMinNumberOfTasks ?? ''}
            contentDesc="BQ Min Number of Tasks Input"
            onChangeText={text => {
              let value = toIntOrUndefined(text);
              return setBQMinNumberOfTasks(value ? text : undefined);
            }}
            textInputRef={bqMinNumberOfTasksRef}
            textInputProps={{
              autoCapitalize: 'none',
              keyboardType: 'number-pad',
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
            contentDesc="Track Screens Toggle"
          />
          <SwitchField
            style={styles.switchRow}
            label="Track Device Attributes"
            onValueChange={() =>
              setTrackDeviceAttributesEnabled(!isTrackDeviceAttributesEnabled)
            }
            value={isTrackDeviceAttributesEnabled}
            contentDesc="Track Device Attributes Toggle"
          />
          <SwitchField
            style={styles.switchRow}
            label="Debug Mode"
            onValueChange={() => setDebugModeEnabled(!isDebugModeEnabled)}
            value={isDebugModeEnabled}
            contentDesc="Debug Mode Toggle"
          />
        </View>
        <View style={styles.buttonContainer}>
          <FilledButton
            style={styles.saveButton}
            onPress={handleSavePress}
            text="Save"
            contentDesc="Save Settings Button"
            textStyle={styles.saveButtonText}
          />
          <TextButton
            style={styles.restoreDefaultsButton}
            onPress={handleRestoreDefaultsPress}
            text="Restore Defaults"
            contentDesc="Restore Default Settings Button"
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
    marginBottom: 4,
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

const setNavigationOptions = (
  navigation: NavigationProp<ParamListBase>,
  handleOnBackPress: () => void,
) => {
  navigation.setOptions({
    headerLeft: (props: any) => (
      <HeaderBackButton
        {...props}
        style={styles.backButton}
        accessibilityLabel="Navigate up"
        onPress={handleOnBackPress}
      />
    ),
  });
};

export default Settings;
