import React, { useState } from 'react';
import { StyleSheet, Text, TextInput, View } from 'react-native';
import { ScrollView } from 'react-native-gesture-handler';
import { FilledButton } from '../components/Button';
import * as Colors from '../constants/Colors';
import * as Fonts from '../constants/Fonts';
import * as Sizes from '../constants/Sizes';
import Screen from '../data/enums/Screen';
import CustomerIOService from '../services/CustomerIOService';
import Prompts from '../utils/prompts';

const Attributes = ({ route }) => {
  const { screen } = route.params;

  const [attributeName, setAttributeName] = useState('');
  const [attributeValue, setAttributeValue] = useState('');

  let title, sendButtonText;
  switch (screen) {
    case Screen.DEVICE_ATTRIBUTES:
      title = 'Set Custom Device Attribute';
      sendButtonText = 'Send device attributes';
      break;

    case Screen.PROFILE_ATTRIBUTES:
      title = 'Set Custom Profile Attribute';
      sendButtonText = 'Send profile attributes';
      break;

    default:
      throw new Error(`Invalid screen prop: ${screen}.`);
  }

  const isFormValid = () => {
    let message;
    let emptyFieldMessageBuilder = (fieldName) => {
      return `${fieldName} cannot be empty`;
    };

    if (!attributeName) {
      message = emptyFieldMessageBuilder('Attribute Name');
    } else if (!attributeValue) {
      message = emptyFieldMessageBuilder('Attribute Value');
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

  const handleSendPress = () => {
    if (!isFormValid()) {
      return;
    }

    switch (screen) {
      case Screen.DEVICE_ATTRIBUTES:
        CustomerIOService.setDeviceAttribute(attributeName, attributeValue);
        Prompts.showSnackbar({ text: 'Device attribute sent successfully!' });
        break;

      case Screen.PROFILE_ATTRIBUTES:
        CustomerIOService.setProfileAttribute(attributeName, attributeValue);
        Prompts.showSnackbar({ text: 'Profile attribute sent successfully!' });
        break;

      default:
        throw new Error(`Invalid screen prop: ${screen}.`);
    }
  };

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <View style={styles.content}>
        <Text style={styles.title}>{title}</Text>

        <View style={styles.inputContainer}>
          <Text style={styles.inputLabel}>Attribute Name</Text>
          <TextInput
            style={styles.input}
            placeholder=""
            onChangeText={(text) => setAttributeName(text)}
            value={attributeName}
          />
        </View>

        <View style={styles.inputContainer}>
          <Text style={styles.inputLabel}>Attribute Value</Text>
          <TextInput
            style={styles.input}
            placeholder=""
            onChangeText={(text) => setAttributeValue(text)}
            value={attributeValue}
          />
        </View>

        <FilledButton
          style={styles.sendButton}
          onPress={handleSendPress}
          text={sendButtonText}
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
  inputContainer: {
    alignItems: 'center',
    flexDirection: 'row',
    marginBottom: 8,
  },
  inputLabel: {
    color: Colors.TEXT_COLOR_PRIMARY,
    fontSize: 14,
    fontWeight: Fonts.FONT_WEIGHT_REGULAR,
    marginRight: 16,
  },
  input: {
    borderBottomWidth: Sizes.INPUT_FIELD_BORDER_WIDTH_BOTTOM,
    borderColor: Colors.INPUT_FIELD_BORDER_COLOR,
    borderRadius: Sizes.INPUT_FIELD_BORDER_RADIUS,
    flex: 1,
    height: Sizes.INPUT_FIELD_HEIGHT,
    maxWidth: Sizes.INPUT_FIELD_MAX_WIDTH,
    paddingHorizontal: Sizes.INPUT_FIELD_PADDING_HORIZONTAL,
  },
  sendButton: {
    marginTop: 24,
  },
});

export default Attributes;
