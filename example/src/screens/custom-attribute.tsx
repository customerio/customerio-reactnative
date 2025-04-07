import {
  Button,
  ButtonExperience,
  LargeBoldText,
  TextField,
} from '@components';

import { NavigationCallbackContext } from '@navigation';
import React, { useContext, useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { showMessage } from 'react-native-flash-message';

export enum CustomAttributePurpose {
  Profile = 'Profile',
  Device = 'Device',
}

type Props = {
  purpose: CustomAttributePurpose;
};

export const CustomAttributeScreen = ({ purpose }: Props) => {
  const { onProfileAttributes, onDeviceAttributes } = useContext(
    NavigationCallbackContext
  );
  const [attribute, setAttribue] = useState({
    name: '',
    value: '',
  });

  return (
    <ScrollView>
      <View style={styles.container}>
        <LargeBoldText>Set Custom {purpose} Attribute</LargeBoldText>
        <TextField
          label="Attribute name"
          value={attribute.name}
          autoCapitalize="none"
          onChangeText={(name) => {
            setAttribue({
              ...attribute,
              ...{ name },
            });
          }}
        />

        <TextField
          label="Attribute value"
          value={attribute.value}
          autoCapitalize="none"
          onChangeText={(value) => {
            setAttribue({
              ...attribute,
              ...{ value },
            });
          }}
        />

        <Button
          title="Send Event"
          experience={ButtonExperience.callToAction}
          onPress={async () => {
            if (purpose === CustomAttributePurpose.Device) {
              onDeviceAttributes({
                [attribute.name]: attribute.value,
              });
            } else {
              onProfileAttributes({
                [attribute.name]: attribute.value,
              });
            }

            showMessage({
              message: `${purpose} attribute set successfully`,
              type: 'success',
            });
          }}
        />
      </View>
    </ScrollView>
  );
};

export const CustomProfileAttrScreen = () => {
  return <CustomAttributeScreen purpose={CustomAttributePurpose.Profile} />;
};

export const CustomDeviceAttrScreen = () => {
  return <CustomAttributeScreen purpose={CustomAttributePurpose.Device} />;
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'column',
    gap: 16,
  },
});
