import React from 'react';
import ReactNative, { StyleSheet } from 'react-native';
import * as Colors from '../constants/Colors';
import * as Fonts from '../constants/Fonts';

interface TextProps {
  children?: React.ReactNode | string;
  style?: ReactNative.StyleProp<ReactNative.TextStyle>;
  contentDesc?: string;
}

export const Text: React.FC<TextProps> = ({
  children,
  style,
  contentDesc,
  ...props
}) => {
  return (
    <ReactNative.Text
      style={[styles.text, style]}
      accessibilityLabel={contentDesc}
      {...props}>
      {children}
    </ReactNative.Text>
  );
};

export const Caption: React.FC<TextProps> = ({ style, ...props }) => {
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
