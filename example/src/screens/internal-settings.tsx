import {
  Button,
  ButtonExperience,
  LargeBoldText,
  TextField,
} from '@components';
import { Storage } from '@services';
import React, { useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { showMessage } from 'react-native-flash-message';

type HostOverrides = {
  apiHost?: string;
  cdnHost?: string;
};

const validateSettings = (overrides: HostOverrides) => {
  if (!overrides.apiHost || !overrides.cdnHost) {
    throw Error('CDN and API host values are missing');
  }
};

export const InternalSettingsScreen = () => {
  const initialConfig = Storage.instance.getCioConfig();
  const [config, setConfig] = useState<HostOverrides>({
    apiHost: initialConfig?.apiHost ?? '',
    cdnHost: initialConfig?.cdnHost ?? '',
  });

  return (
    <ScrollView>
      <View style={styles.container}>
        <LargeBoldText>CIO Internal Settings</LargeBoldText>
        <TextField
          onChangeText={(cdnHost) => {
            setConfig({ ...config, cdnHost });
          }}
          label="CDN Host"
          placeholder="Enter the CDN Host"
          defaultValue={config.cdnHost ?? ''}
        />

        <TextField
          onChangeText={(apiHost) => {
            setConfig({ ...config, apiHost });
          }}
          label="API Host"
          placeholder="Enter the API host"
          defaultValue={config.apiHost ?? ''}
        />

        <Button
          title="Save"
          experience={ButtonExperience.callToAction}
          disabled={!config.apiHost || !config.cdnHost}
          onPress={async () => {
            try {
              validateSettings(config);
              await Storage.instance.setCioConfig({
                ...Storage.instance.getCioConfig(),
                apiHost: config.apiHost,
                cdnHost: config.cdnHost,
              });

              showMessage({
                message: 'Internal Settings saved successfully',
                type: 'success',
              });
            } catch (error: unknown) {
              showMessage({
                message: (error as Error).message,
                type: 'warning',
              });
              return;
            }
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
