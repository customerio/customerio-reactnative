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
          footnote="Optional: Only needed for migration from older SDK versions and to enable in-app messaging"
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
          value={config.inApp?.siteId !== undefined}
          onValueChange={(enableInApp) => {
            const inApp = enableInApp
              ? { siteId: config.inApp?.siteId ?? '' }
              : undefined;
            setConfig({ ...config, inApp });
          }}
          disabled={!config.inApp?.siteId || config.inApp?.siteId.length === 0}
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
            if (!config.cdpApiKey && !config.inApp?.siteId) {
              missing = 'CDP API Key and Site ID values are missing';
            } else if (!config.inApp?.siteId) {
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
