import {
  Button,
  ButtonExperience,
  HorizontalLineSeparator,
  LargeBoldText,
  SingleSelect,
  Switch,
  TextField,
} from '@components';
import { Storage } from '@services';
import { withInboxAccessibilityLabels } from '@utils';
import {
  CioConfig,
  CioLocationTrackingMode,
  CioLogLevel,
  CioRegion,
  CustomerIO,
} from 'customerio-reactnative';
import React, { useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { showMessage } from 'react-native-flash-message';

export const SettingsScreen = () => {
  const [config, setConfig] = useState<Partial<CioConfig>>(
    Storage.instance.getCioConfig() ?? Storage.instance.getDefaultCioConfig()
  );

  return (
    <ScrollView>
      <View style={styles.container}>
        <LargeBoldText>CustomerIO Configs</LargeBoldText>
        <TextField
          onChangeText={(cdpApiKey) => {
            setConfig({ ...config, cdpApiKey });
          }}
          label="CDP API Key"
          placeholder="Enter your CDP API key"
          defaultValue={config.cdpApiKey ?? ''}
        />
        <TextField
          onChangeText={(siteId) => {
            const inApp = { siteId: siteId };
            setConfig({ ...config, inApp });
          }}
          label="Site ID"
          placeholder="Enter your site ID"
          footnote="Optional: Only needed for migration from older SDK versions, or for in-app messaging without a wk_ key"
          defaultValue={config.inApp?.siteId ?? ''}
        />

        <SingleSelect<CioRegion>
          data={[
            { label: 'US', value: CioRegion.US },
            { label: 'EU', value: CioRegion.EU },
          ]}
          onValueChange={(region) => {
            setConfig({ ...config, region });
          }}
          selectedValue={config.region ?? CioRegion.US}
          label="Region"
        />

        <SingleSelect<CioLocationTrackingMode>
          data={[
            { label: 'Off', value: CioLocationTrackingMode.Off },
            { label: 'Manual', value: CioLocationTrackingMode.Manual },
            {
              label: 'On App Start',
              value: CioLocationTrackingMode.OnAppStart,
            },
          ]}
          onValueChange={(trackingMode) => {
            setConfig({
              ...config,
              location: { ...config.location, trackingMode },
            });
          }}
          selectedValue={
            config.location?.trackingMode ?? CioLocationTrackingMode.Manual
          }
          label="Location Tracking Mode"
          fullWidth
        />

        <Switch
          label="Track Application Lifecycle Events"
          value={config.trackApplicationLifecycleEvents}
          onValueChange={(trackApplicationLifecycleEvents) => {
            setConfig({ ...config, trackApplicationLifecycleEvents });
          }}
        />

        <HorizontalLineSeparator />

        <LargeBoldText>Features</LargeBoldText>
        <Switch
          label="Enable In-App Messaging"
          value={config.inApp !== undefined}
          onValueChange={(enableInApp) => {
            const inApp = enableInApp
              ? { siteId: config.inApp?.siteId }
              : undefined;
            setConfig({ ...config, inApp });
          }}
        />

        <HorizontalLineSeparator />
        <LargeBoldText>Debug</LargeBoldText>
        <Switch
          label="Enable Debug Logging"
          value={config.logLevel === CioLogLevel.Debug}
          onValueChange={(enabled) => {
            setConfig({
              ...config,
              logLevel: enabled ? CioLogLevel.Debug : undefined,
            });
          }}
        />

        <Button
          title="Save"
          experience={ButtonExperience.callToAction}
          disabled={!config.cdpApiKey}
          onPress={() => {
            Storage.instance.setCioConfig(config as CioConfig);
            let missing = '';
            if (!config.cdpApiKey) {
              missing = 'CDP API Key value is missing';
            }
            if (missing.length > 0) {
              showMessage({
                message: `CustomerIO settings are saved but ${missing}.`,
                type: 'warning',
              });
            } else {
              CustomerIO.initialize(
                withInboxAccessibilityLabels(config as CioConfig)
              );
              showMessage({
                message:
                  'CustomerIO settings saved successfully and CustomerIO.initialize() has been called with the new settings',
                type: 'success',
              });
            }
          }}
        />

        <Button
          title="Reset to Default"
          experience={ButtonExperience.secondary}
          onPress={() => {
            Storage.instance.resetCioConfig();
            showMessage({
              message: 'CustomerIO settings has been reset!',
              type: 'success',
            });
          }}
        />
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
    flexDirection: 'column',
    gap: 16,
  },
});
