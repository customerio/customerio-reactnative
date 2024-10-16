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
import {styles as settingsStyles} from '../styles/stylesheet';
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
  const initialCdpApiKey = params?.api_key;
  const { config: initialConfig, onSdkConfigStateChanged } =
    useCustomerIoSdkContext();
  const { user } = useUserStateContext();
  const defaultConfig = CustomerIoSDKConfig.createDefault();

  // Will be used once we roll out feature for exposing device token
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [deviceToken, setDeviceToken] = useState('');
  const [siteId, setSiteId] = useState('');
  const [cdpApiKey, setCdpApiKey] = useState('');
  const [isTrackScreensEnabled, setTrackScreensEnabled] = useState(false);
  const [isTrackDeviceAttributesEnabled, setTrackDeviceAttributesEnabled] =
    useState(false);
  const [isDebugModeEnabled, setDebugModeEnabled] = useState(false);
  const [isAppLifecycleEventTrackingEnabled, setAppLifecycleEventTrackingEnabled] = useState(false);

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
    
    CustomerIO.pushMessaging
      .getRegisteredDeviceToken()
      .then((token) => {
        setDeviceToken(token);
      })
      .catch((error) => {
        console.log(error);
      });
    
    setValueIfPresent(initialSiteId ?? initialConfig?.siteId, setSiteId);
    setValueIfPresent(initialCdpApiKey ?? initialConfig?.cdpApiKey, setCdpApiKey);
    setValueIfPresent(initialConfig?.trackScreens, setTrackScreensEnabled);
    setValueIfPresent(
      initialConfig?.trackDeviceAttributes,
      setTrackDeviceAttributesEnabled,
    );
    setValueIfPresent(initialConfig?.debugMode, setDebugModeEnabled);
    setValueIfPresent(initialConfig?.trackAppLifecycleEvents, setAppLifecycleEventTrackingEnabled);

  }, [initialCdpApiKey, initialConfig, initialSiteId]);

  const handleRestoreDefaultsPress = async () => {
    saveConfigurations(defaultConfig);
  };

  const isFormValid = () => {
    let message;
    let blankFieldMessageBuilder = (fieldName: string) => {
      return `${fieldName} cannot be blank`;
    };
    if (!cdpApiKey) {
      message = blankFieldMessageBuilder('CDP API Key');
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
    config.cdpApiKey = cdpApiKey;
    config.trackScreens = isTrackScreensEnabled;
    config.trackDeviceAttributes = isTrackDeviceAttributesEnabled;
    config.debugMode = isDebugModeEnabled;
    config.trackAppLifecycleEvents = isAppLifecycleEventTrackingEnabled;
    saveConfigurations(config);
    navigation.goBack();
  };

  const saveConfigurations = async (config: CustomerIoSDKConfig) => {
    await onSdkConfigStateChanged(config);
  };

  const copyToDeviceClipboard = async () => {
    Clipboard.setString(deviceToken);
    Prompts.showSnackbar({ text: 'Device token copied to clipboard' });
  };

  const handleGoToInternalSettingsPress = async () => {
    navigation.navigate('InternalSettings');
  }

  const siteIdRef = useRef();
  const apiKeyRef = useRef();

  return (
    <View style={settingsStyles.container}>
      <ScrollView contentContainerStyle={settingsStyles.content}>
        <View style={settingsStyles.section}>
          <TextField
            style={settingsStyles.textInputContainer}
            label="Device Token"
            value={deviceToken}
            contentDesc="Device Token Input"
            editable={false}
            leadingIconImageSource={require('../../assets/images/ic_copy.png')}
            onLeadingIconPress={() => copyToDeviceClipboard()}
          />
        </View>
        <View style={settingsStyles.section}>
        <Text style={settingsStyles.sectionLabel}>Config Settings</Text>
          <TextField
            style={settingsStyles.textInputContainer}
            label="Site Id"
            value={siteId}
            contentDesc="Site ID Input"
            onChangeText={text => setSiteId(text)}
            textInputRef={siteIdRef}
            getNextTextInput={() => ({ ref: apiKeyRef, value: cdpApiKey })}
            textInputProps={{
              autoCapitalize: 'none',
              keyboardType: 'default',
            }}
          />
          <TextField
            style={settingsStyles.textInputContainer}
            label="CDP API Key"
            value={cdpApiKey}
            contentDesc="CDP API Key Input"
            onChangeText={text => setCdpApiKey(text)}
            textInputRef={apiKeyRef}
            textInputProps={{
              autoCapitalize: 'none',
              keyboardType: 'default',
            }}
          />
        </View>
        <View style={settingsStyles.section}>
          <SwitchField
            style={settingsStyles.switchRow}
            label="Track Screens"
            onValueChange={() => setTrackScreensEnabled(!isTrackScreensEnabled)}
            value={isTrackScreensEnabled}
            contentDesc="Track Screens Toggle"
          />
          <SwitchField
            style={settingsStyles.switchRow}
            label="Track Device Attributes"
            onValueChange={() =>
              setTrackDeviceAttributesEnabled(!isTrackDeviceAttributesEnabled)
            }
            value={isTrackDeviceAttributesEnabled}
            contentDesc="Track Device Attributes Toggle"
          />
          <SwitchField
            style={settingsStyles.switchRow}
            label="App Lifecycle Events Tracking"
            onValueChange={() => setAppLifecycleEventTrackingEnabled(!isAppLifecycleEventTrackingEnabled)}
            value={isAppLifecycleEventTrackingEnabled}
            contentDesc="App Lifecycle Events Tracking Toggle"
          />
        </View>
        <View style={settingsStyles.section}>
        <Text style={settingsStyles.sectionLabel}>Development</Text>
        <SwitchField
            style={settingsStyles.switchRow}
            label="Debug Mode"
            onValueChange={() => setDebugModeEnabled(!isDebugModeEnabled)}
            value={isDebugModeEnabled}
            contentDesc="Debug Mode Toggle"
          />
          </View>
        <View style={settingsStyles.buttonContainer}>
          <FilledButton
            style={settingsStyles.saveButton}
            onPress={handleSavePress}
            text="Save"
            contentDesc="Save Settings Button"
            textStyle={settingsStyles.saveButtonText}
          />
          <FilledButton
            style={settingsStyles.saveButton}
            onPress={handleGoToInternalSettingsPress}
            text="Internal Settings"
            contentDesc="Internal Settings Button"
            textStyle={settingsStyles.saveButtonText}
          />
          <TextButton
            style={settingsStyles.restoreDefaultsButton}
            onPress={handleRestoreDefaultsPress}
            text="Restore Defaults"
            contentDesc="Restore Default Settings Button"
          />
          <Caption style={settingsStyles.note}>
            Note: You must restart the app to apply these settings
          </Caption>
        </View>
      </ScrollView>
    </View>
  );
};
const setNavigationOptions = (
  navigation: NavigationProp<ParamListBase>,
  handleOnBackPress: () => void,
) => {
  navigation.setOptions({
    headerLeft: (props: any) => (
      <HeaderBackButton
        {...props}
        style={settingsStyles.backButton}
        accessibilityLabel="Navigate up"
        onPress={handleOnBackPress}
      />
    ),
  });
};

export default Settings;
