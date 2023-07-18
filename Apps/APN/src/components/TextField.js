import React from 'react';
import {
  Image,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import * as Colors from '../constants/Colors';
import * as Fonts from '../constants/Fonts';
import * as Sizes from '../constants/Sizes';
import { Text } from './Text';

export const TextField = ({
  value,
  label,
  placeholder,
  onChangeText,
  editable,
  style,
  labelStyle,
  labelProps,
  textInputStyle,
  textInputProps,
  textInputRef,
  getNextTextInput,
  leadingIconImageSource,
  onLeadingIconPress,
  leadingIconContainerStyle,
  leadingIconContainerProps,
  leadingIconImageStyle,
  leadingIconImageProps,
  ...props
}) => {
  const focusNextField = () => {
    const { ref: nextTextInputRef, value: nextTextInputValue } =
      getNextTextInput();
    const nextTextInput = nextTextInputRef?.current;
    if (!nextTextInput) {
      return;
    }

    // By default, focus moves to the beginning of the text input by calling focus()
    nextTextInput.focus();

    // Set cursor to end of text input for better user experience
    const length = nextTextInputValue?.toString()?.length ?? 0;
    if (length > 0) {
      nextTextInput.setNativeProps({
        selection: {
          start: length,
          end: length,
        },
      });
      // Clear selection after 0ms to prevent cursor from showing up constantly at the selection set above
      setTimeout(() => nextTextInput.setNativeProps({ selection: null }), 0);
    }
  };

  let blurOnSubmit;
  let onSubmitEditing;
  let returnKeyType;

  // If getNextTextInput is not defined, then this text input is the last one in the form
  if (getNextTextInput) {
    blurOnSubmit = false;
    onSubmitEditing = () => focusNextField();
    returnKeyType = 'next';
  } else {
    returnKeyType = 'done';
  }

  return (
    <View style={[styles.row, style]} {...props}>
      {label && (
        <Text style={[styles.label, labelStyle]} {...labelProps}>
          {label}
        </Text>
      )}
      <TextInput
        style={[styles.textInput, textInputStyle]}
        onChangeText={onChangeText}
        value={value}
        placeholder={placeholder}
        editable={editable}
        ref={textInputRef}
        blurOnSubmit={blurOnSubmit}
        onSubmitEditing={onSubmitEditing}
        returnKeyType={returnKeyType}
        {...textInputProps}
      />
      {leadingIconImageSource && (
        <TouchableOpacity
          style={[styles.leadingIconContainer, leadingIconContainerStyle]}
          onPress={onLeadingIconPress}
          {...leadingIconContainerProps}
        >
          <Image
            style={[styles.leadingIconImage, leadingIconImageStyle]}
            source={leadingIconImageSource}
            {...leadingIconImageProps}
          />
        </TouchableOpacity>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  row: {
    alignItems: 'center',
    flexDirection: 'row',
  },
  label: {
    fontSize: 14,
    fontWeight: Fonts.FONT_WEIGHT_REGULAR,
    marginRight: 16,
    textAlign: 'left',
  },
  textInput: {
    borderBottomWidth: Sizes.INPUT_FIELD_BORDER_WIDTH_BOTTOM,
    borderColor: Colors.INPUT_FIELD_BORDER_COLOR,
    borderRadius: Sizes.INPUT_FIELD_BORDER_RADIUS,
    flex: 1,
    height: Sizes.INPUT_FIELD_HEIGHT,
    maxWidth: Sizes.INPUT_FIELD_MAX_WIDTH,
    paddingHorizontal: Sizes.INPUT_FIELD_PADDING_HORIZONTAL,
  },
  leadingIconContainer: {
    alignContent: 'center',
    justifyContent: 'center',
  },
  leadingIconImage: {
    alignSelf: 'center',
    height: Sizes.IMAGE_BUTTON_ICON_SIZE,
    width: Sizes.IMAGE_BUTTON_ICON_SIZE,
  },
});
