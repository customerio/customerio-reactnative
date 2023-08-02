import React from 'react';
import { Text as ReactNativeText, StyleSheet } from 'react-native';
import * as Colors from '../constants/Colors';
import * as Fonts from '../constants/Fonts';

export const Text = ({ children, style, contentDesc, ...props }) => {
  return (
    <ReactNativeText
      style={[styles.text, style]}
      accessibilityLabel={contentDesc}
      {...props}>
      {children}
    </ReactNativeText>
  );
};

export const Caption = ({ style, ...props }) => {
  return <Text style={[styles.caption, style]} {...props} />;
};

const styles = StyleSheet.create({
  caption: {
    color: Colors.TEXT_COLOR_TERTIARY,
    fontSize: 12,
  },
  text: {
    alignSelf: 'center',
    color: Colors.TEXT_COLOR_PRIMARY,
    fontWeight: Fonts.FONT_WEIGHT_REGULAR,
    fontSize: 14,
    textAlign: 'center',
  },
});
