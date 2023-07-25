import React, { useRef, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { ScrollView } from 'react-native-gesture-handler';
import { FilledButton } from '../components/Button';
import { Text } from '../components/Text';
import { TextField } from '../components/TextField';
import * as Colors from '../constants/Colors';
import Screen from '../data/enums/Screen';
import {
  trackDeviceAttribute,
  trackProfileAttribute,
} from '../services/CustomerIOService';
import Prompts from '../utils/prompts';

const Attributes = ({ route }) => {
  const { screen } = route.params;

  const [attributeName, setAttributeName] = useState('');
  const [attributeValue, setAttributeValue] = useState('');

  let title, sendButtonText, sendButtonContentDesc;
  switch (screen) {
    case Screen.DEVICE_ATTRIBUTES:
      title = 'Set Custom Device Attribute';
      sendButtonText = 'Send device attributes';
      sendButtonContentDesc = 'Set Device Attribute Button';
      break;

    case Screen.PROFILE_ATTRIBUTES:
      title = 'Set Custom Profile Attribute';
      sendButtonText = 'Send profile attributes';
      sendButtonContentDesc = 'Set Profile Attribute Button';
      break;

    default:
      throw new Error(`Invalid screen prop: ${screen}.`);
  }

  const handleSendPress = () => {
    switch (screen) {
      case Screen.DEVICE_ATTRIBUTES:
        trackDeviceAttribute(attributeName, attributeValue);
        Prompts.showSnackbar({ text: 'Device attribute sent successfully!' });
        break;

      case Screen.PROFILE_ATTRIBUTES:
        trackProfileAttribute(attributeName, attributeValue);
        Prompts.showSnackbar({ text: 'Profile attribute sent successfully!' });
        break;

      default:
        throw new Error(`Invalid screen prop: ${screen}.`);
    }
  };

  const attributeNameRef = useRef();
  const attributeValueRef = useRef();

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <View style={styles.content}>
        <Text style={styles.title}>{title}</Text>

        <TextField
          style={styles.textInputContainer}
          label="Attribute Name"
          placeholder=""
          onChangeText={(text) => setAttributeName(text)}
          value={attributeName}
          contentDesc="Attribute Name Input"
          textInputRef={attributeNameRef}
          getNextTextInput={() => ({
            ref: attributeValueRef,
            value: attributeValue,
          })}
          textInputProps={{
            autoCapitalize: 'none',
            keyboardType: 'default',
          }}
        />

        <TextField
          style={styles.textInputContainer}
          label="Attribute Value"
          placeholder=""
          onChangeText={(text) => setAttributeValue(text)}
          value={attributeValue}
          contentDesc="Attribute Value Input"
          textInputRef={attributeValueRef}
          textInputProps={{
            autoCapitalize: 'none',
            keyboardType: 'default',
          }}
        />

        <FilledButton
          style={styles.sendButton}
          onPress={handleSendPress}
          text={sendButtonText}
          contentDesc={sendButtonContentDesc}
        />
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: Colors.CONTAINER_BACKGROUND_COLOR,
    flex: 1,
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 20,
  },
  title: {
    alignSelf: 'flex-start',
    fontSize: 22,
    marginBottom: 32,
  },
  textInputContainer: {
    marginBottom: 8,
  },
  sendButton: {
    marginTop: 24,
  },
});

export default Attributes;
