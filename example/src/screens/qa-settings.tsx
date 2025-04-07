import {
  Button,
  ButtonExperience,
  LargeBoldText,
  TextField,
} from '@components';
import { QASettings, Storage } from '@services';
import React, { useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { showMessage } from 'react-native-flash-message';

const validateSettings = (config: QASettings) => {
  if (!config.apiHost || !config.cdnHost) {
    throw Error('CDN and API host values are missing');
  } else if (!config.cdnHost) {
    throw Error('CDB Host value is missing');
  } else if (!config.apiHost) {
    throw Error('API Host value is missing');
  }
};

export const QASettingsScreen = () => {
  const [config, setConfig] = useState<QASettings>(
    Storage.instance.getQaConfig()
  );

  return (
    <ScrollView>
      <View style={styles.container}>
        <LargeBoldText>CustomerIO QA Settings</LargeBoldText>
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
              Storage.instance.setQaConfig(config);

              showMessage({
                message: 'QA settings saved successfully',
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
