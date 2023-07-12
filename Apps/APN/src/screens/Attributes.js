import React from 'react';
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
import Screen from '../data/enums/Screen';

const Attributes = ({ screen }) => {
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

  const handleSendPressed = () => {
    switch (screen) {
      case Screen.DEVICE_ATTRIBUTES:
        break;

      case Screen.PROFILE_ATTRIBUTES:
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
          <TextInput style={styles.input} placeholder="" />
        </View>

        <View style={styles.inputContainer}>
          <Text style={styles.inputLabel}>Attribute Value</Text>
          <TextInput style={styles.input} placeholder="" />
        </View>

        <TouchableOpacity style={styles.sendButton} onPress={handleSendPressed}>
          <Text style={styles.sendButtonText}>{sendButtonText}</Text>
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
    alignSelf: 'left',
    color: Colors.TEXT_COLOR_PRIMARY,
    fontFamily: Fonts.FONT_FAMILY_REGULAR,
    fontSize: 20,
    fontWeight: Colors.FONT_WEIGHT_REGULAR,
    marginBottom: 16,
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
    textTransform: 'uppercase',
  },
});

export default Attributes;
