import React from 'react';
import { StyleSheet, TouchableOpacity } from 'react-native';
import * as Colors from '../constants/Colors';
import * as Fonts from '../constants/Fonts';
import * as Sizes from '../constants/Sizes';
import { Text } from './Text';

export const FilledButton = ({
  text,
  onPress,
  style,
  textStyle,
  textProps,
  contentDesc,
  ...props
}) => {
  return (
    <TouchableOpacity
      style={[styles.filledButtonContainer, style]}
      onPress={onPress}
      accessibilityLabel={contentDesc}
      {...props}
    >
      <Text style={[styles.filledButtonText, textStyle]} {...textProps}>
        {text}
      </Text>
    </TouchableOpacity>
  );
};

export const TextButton = ({
  text,
  onPress,
  style,
  textStyle,
  textProps,
  contentDesc,
  ...props
}) => {
  return (
    <TouchableOpacity
      style={[styles.textButtonContainer, style]}
      onPress={onPress}
      accessibilityLabel={contentDesc}
      {...props}
    >
      <Text style={[styles.textButtonText, textStyle]} {...textProps}>
        {text}
      </Text>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  filledButtonContainer: {
    alignItems: 'center',
    backgroundColor: Colors.PRIMARY_COLOR,
    borderRadius: Sizes.BUTTON_BORDER_RADIUS,
    color: Colors.TEXT_COLOR_ON_PRIMARY,
    justifyContent: 'center',
    paddingHorizontal: Sizes.BUTTON_PADDING_HORIZONTAL,
    paddingVertical: Sizes.BUTTON_PADDING_VERTICAL,
    maxWidth: Sizes.BUTTON_MAX_WIDTH,
    width: '80%',
  },
  filledButtonText: {
    color: Colors.TEXT_COLOR_ON_PRIMARY,
    fontSize: Fonts.FONT_SIZE_BUTTON_DEFAULT,
    fontWeight: Fonts.FONT_FAMILY_BOLD,
    textAlign: 'center',
  },
  textButtonContainer: {
    alignItems: 'center',
    borderRadius: Sizes.BUTTON_BORDER_RADIUS,
    color: Colors.SECONDARY_COLOR,
    justifyContent: 'center',
    paddingHorizontal: Sizes.BUTTON_PADDING_HORIZONTAL,
    paddingVertical: Sizes.BUTTON_PADDING_VERTICAL,
    marginTop: 16,
    maxWidth: Sizes.BUTTON_MAX_WIDTH,
    width: '80%',
  },
  textButtonText: {
    color: Colors.SECONDARY_COLOR,
    fontSize: Fonts.FONT_SIZE_BUTTON_DEFAULT,
    fontWeight: Fonts.FONT_FAMILY_BOLD,
    textAlign: 'center',
  },
});
