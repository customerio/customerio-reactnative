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
  leadingIconImageSource,
  onLeadingIconPress,
  leadingIconContainerStyle,
  leadingIconContainerProps,
  leadingIconImageStyle,
  leadingIconImageProps,
  ...props
}) => {
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
        editable={editable ?? true}
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
