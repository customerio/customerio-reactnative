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
import {
  CioConfig,
  CioLogLevel,
  CioRegion,
  CustomerIO,
} from 'customerio-reactnative';
import React, { useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { showMessage } from 'react-native-flash-message';

const defaultCioConfig: Partial<CioConfig> = {
  region: CioRegion.US,
  logLevel: CioLogLevel.Error,
  trackApplicationLifecycleEvents: true,
};

export const SettingsScreen = () => {
  const [config, setConfig] = useState<Partial<CioConfig>>(
    Storage.instance.getCioConfig() ?? defaultCioConfig
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
            setConfig({ ...config, siteId });
          }}
          label="Site ID"
          placeholder="Enter your site ID"
          footnote="Optional: Only needed for migration from older SDK versions and to enable in-app messaging"
          defaultValue={config.siteId ?? ''}
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
          value={config.enableInApp ?? false}
          onValueChange={(enableInApp) => {
            setConfig({ ...config, enableInApp });
          }}
          disabled={!config.siteId || config.siteId.length === 0}
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
            if (!config.cdpApiKey && !config.siteId) {
              missing = 'CDP API Key and Site ID values are missing';
            } else if (!config.siteId) {
              missing = 'Site ID value is missing';
            } else if (!config.cdpApiKey) {
              missing = 'CDP API Key value is missing';
            }
            if (missing.length > 0) {
              showMessage({
                message: `CustomerIO settings are saved but ${missing}.`,
                type: 'warning',
              });
            } else {
              CustomerIO.initialize(config as CioConfig);
              showMessage({
                message:
                  'CustomerIO settings saved successfully CustomerIO.initialize() has been called with the new settings',
                type: 'success',
              });
            }
          }}
        />

        <Button
          title="Reset to Default"
          experience={ButtonExperience.secondary}
          onPress={() => {
            setConfig(defaultCioConfig);
            Storage.instance.setCioConfig(defaultCioConfig as CioConfig);
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
