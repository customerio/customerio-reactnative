import { HeaderBackButton } from '@react-navigation/elements';
import { useFocusEffect } from '@react-navigation/native';
import React, {
  useCallback,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
} from 'react';
import {
  BackHandler,
  Clipboard,
  Platform,
  ScrollView,
  StyleSheet,
  View,
  TouchableOpacity,
} from 'react-native';
import { FilledButton, TextButton } from '../components/Button';
import { SwitchField } from '../components/SwitchField';
import { Caption, Text } from '../components/Text';
import { TextField } from '../components/TextField';
import { styles as settingsStyles } from '../styles/stylesheet';
import CustomerIoSDKConfig from '../data/sdk/CustomerIoSDKConfig';
import { useCustomerIoSdkContext } from '../state/customerIoSdkState';
import { useUserStateContext } from '../state/userState';
import { resetRoute } from '../utils/navigation';
import Prompts from '../utils/prompts';
import { CustomerIO, ScreenView } from 'customerio-reactnative';

const Settings = ({ navigation, route }) => {
  const { params } = route;
  const initialSiteId = params?.site_id;
  const initialCdpApiKey = params?.api_key;
  const { config: initialConfig, onSdkConfigStateChanged } =
    useCustomerIoSdkContext();
  const { user } = useUserStateContext();
  const defaultConfig = CustomerIoSDKConfig.createDefault();

  const [deviceToken, setDeviceToken] = useState('');
  const [siteId, setSiteId] = useState('');
  const [cdpApiKey, setCdpApiKey] = useState('');
  const [isTrackScreensEnabled, setTrackScreensEnabled] = useState(false);
  const [isTrackDeviceAttributesEnabled, setTrackDeviceAttributesEnabled] =
    useState(false);
  const [isDebugModeEnabled, setDebugModeEnabled] = useState(false);
  const [
    isAppLifecycleEventTrackingEnabled,
    setAppLifecycleEventTrackingEnabled,
  ] = useState(false);

  const handleOnBackPress = useCallback(() => {
    if (!navigation.canGoBack()) {
      resetRoute(navigation, user);
      return true;
    }

    return false;
  }, [navigation, user]);

  const [screenView, setScreenView] = useState(ScreenView.All.toString());

  useLayoutEffect(() => {
    if (!navigation.canGoBack()) {
      navigation.setOptions({
        headerLeft: (props) => (
          <HeaderBackButton
            {...props}
            style={settingsStyles.backButton}
            labelVisible={Platform.OS === 'ios'}
            accessibilityLabel="Navigate up"
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
    CustomerIO.pushMessaging
      .getRegisteredDeviceToken()
      .then((token) => {
        setDeviceToken(token);
      })
      .catch((error) => {
        console.log(error);
      });
    setSiteId(initialSiteId ?? initialConfig.siteId);
    setCdpApiKey(initialCdpApiKey ?? initialConfig.cdpApiKey);
    setTrackScreensEnabled(initialConfig.trackScreens);
    setTrackDeviceAttributesEnabled(initialConfig.trackDeviceAttributes);
    setDebugModeEnabled(initialConfig.debugMode);
    setScreenView(initialConfig.screenViewUse);
    setAppLifecycleEventTrackingEnabled(initialConfig?.trackAppLifecycleEvents);
  }, [initialCdpApiKey, initialConfig, initialSiteId]);

  const handleRestoreDefaultsPress = async () => {
    saveConfigurations(defaultConfig);
  };

  const isFormValid = () => {
    let message;
    let blankFieldMessageBuilder = (fieldName) => {
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
    config.screenViewUse = screenView;
    saveConfigurations(config);
    navigation.goBack();
  };

  const saveConfigurations = async (config) => {
    await onSdkConfigStateChanged(config);
  };

  const copyToDeviceClipboard = async () => {
    Clipboard.setString(deviceToken);
    Prompts.showSnackbar({ text: 'Device token copied to clipboard' });
  };

  const siteIdRef = useRef();
  const apiKeyRef = useRef();

  const handleGoToInternalSettingsPress = async () => {
    navigation.navigate('InternalSettings');
  };
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
            leadingIconImageSource={require('../../assets/images/paper.png')}
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
            onChangeText={(text) => setSiteId(text)}
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
            contentDesc="CDP Api Key Input"
            onChangeText={(text) => setCdpApiKey(text)}
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
            label="App Lifecycle Events Tracking"
            onValueChange={() =>
              setAppLifecycleEventTrackingEnabled(
                !isAppLifecycleEventTrackingEnabled
              )
            }
            value={isAppLifecycleEventTrackingEnabled}
            contentDesc="App Lifecycle Events Tracking Toggle"
          />
        </View>
        <SwitchField
          style={settingsStyles.switchRow}
          label="Auto track device attributes"
          onValueChange={() =>
            setTrackDeviceAttributesEnabled(!isTrackDeviceAttributesEnabled)
          }
          value={isTrackDeviceAttributesEnabled}
          contentDesc="Auto track device attributes Toggle"
        />
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
        <View style={settingsStyles.section}>
          <Text style={settingsStyles.sectionLabel}>ScreenView Use</Text>
          <View
            style={[
              settingsStyles.buttonGroup,
              { backgroundColor: '#F0F0F5', borderRadius: 8 },
            ]}
          >
            <TouchableOpacity
              style={[
                settingsStyles.segmentButton,
                { flex: 1 },
                screenView === ScreenView.All.toString() && {
                  backgroundColor: '#4B48C9',
                },
              ]}
              onPress={() => setScreenView(ScreenView.All.toString())}
            >
              <Text
                style={[
                  settingsStyles.segmentButtonText,
                  screenView === ScreenView.All.toString() && {
                    color: 'white',
                  },
                ]}
              >
                All
              </Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[
                settingsStyles.segmentButton,
                { flex: 1 },
                screenView === ScreenView.InApp.toString() && {
                  backgroundColor: '#4B48C9',
                },
              ]}
              onPress={() => setScreenView(ScreenView.InApp.toString())}
            >
              <Text
                style={[
                  settingsStyles.segmentButtonText,
                  screenView === ScreenView.InApp.toString() && {
                    color: 'white',
                  },
                ]}
              >
                InApp
              </Text>
            </TouchableOpacity>
          </View>
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

export default Settings;
