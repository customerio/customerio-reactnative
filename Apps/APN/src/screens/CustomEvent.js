import React, { useState } from 'react';
import {
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { ScrollView } from 'react-native-gesture-handler';
import * as Colors from '../constants/Colors';
import * as Fonts from '../constants/Fonts';
import * as Sizes from '../constants/Sizes';
import CustomerIOService from '../services/CustomerIOService';
import Prompts from '../utils/prompts';

const CustomEvent = () => {
  const [eventName, setEventName] = useState('');
  const [propertyName, setPropertyName] = useState('');
  const [propertyValue, setPropertyValue] = useState('');

  const isFormValid = () => {
    let message;
    let emptyFieldMessageBuilder = (fieldName) => {
      return `${fieldName} cannot be empty`;
    };

    if (!eventName) {
      message = emptyFieldMessageBuilder('Event Name');
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

    CustomerIOService.sendEvent(eventName, propertyName, propertyValue);
    Prompts.showSnackbar({ text: 'Event sent successfully' });
  };

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <View style={styles.content}>
        <Text style={styles.title}>Send Custom Event</Text>

        <View style={styles.inputContainer}>
          <Text style={styles.inputLabel}>Event Name</Text>
          <TextInput
            style={styles.input}
            placeholder=""
            onChangeText={(text) => setEventName(text)}
            value={eventName}
          />
        </View>

        <View style={styles.inputContainer}>
          <Text style={styles.inputLabel}>Property Name</Text>
          <TextInput
            style={styles.input}
            placeholder=""
            onChangeText={(text) => setPropertyName(text)}
            value={propertyName}
          />
        </View>

        <View style={styles.inputContainer}>
          <Text style={styles.inputLabel}>Property Value</Text>
          <TextInput
            style={styles.input}
            placeholder=""
            onChangeText={(text) => setPropertyValue(text)}
            value={propertyValue}
          />
        </View>

        <TouchableOpacity style={styles.sendButton} onPress={handleSendPress}>
          <Text style={styles.sendButtonText}>Send Event Button</Text>
        </TouchableOpacity>
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
    color: Colors.TEXT_COLOR_PRIMARY,
    fontFamily: Fonts.FONT_FAMILY_REGULAR,
    fontSize: 20,
    fontWeight: Colors.FONT_WEIGHT_REGULAR,
    marginBottom: 32,
  },
  inputContainer: {
    alignItems: 'center',
    flexDirection: 'row',
    marginBottom: 8,
  },
  inputLabel: {
    color: Colors.TEXT_COLOR_PRIMARY,
    fontFamily: Fonts.FONT_FAMILY_REGULAR,
    fontSize: 14,
    fontWeight: Fonts.FONT_WEIGHT_REGULAR,
    marginRight: 16,
    minWidth: 100,
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
    backgroundColor: Colors.PRIMARY_COLOR,
    borderRadius: Sizes.BUTTON_BORDER_RADIUS,
    marginTop: 24,
    paddingHorizontal: Sizes.BUTTON_PADDING_HORIZONTAL,
    paddingVertical: Sizes.BUTTON_PADDING_VERTICAL,
    maxWidth: Sizes.BUTTON_MAX_WIDTH,
    width: Sizes.BUTTON_MAX_WIDTH,
  },
  sendButtonText: {
    color: Colors.TEXT_COLOR_ON_PRIMARY,
    fontFamily: Fonts.FONT_FAMILY_REGULAR,
    fontSize: Fonts.FONT_SIZE_BUTTON_DEFAULT,
    fontWeight: Fonts.FONT_FAMILY_BOLD,
    textAlign: 'center',
  },
});

export default CustomEvent;
