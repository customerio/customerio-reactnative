import React from 'react';
import { StyleSheet, Switch, View } from 'react-native';
import * as Colors from '../constants/Colors';
import * as Fonts from '../constants/Fonts';
import { Text } from './Text';

export const SwitchField = ({
  value,
  label,
  onValueChange,
  style,
  labelStyle,
  labelProps,
  switchStyle,
  switchProps,
  ...props
}) => {
  return (
    <View style={[styles.row, style]} {...props}>
      {label && (
        <Text style={[styles.label, labelStyle]} {...labelProps}>
          {label}
        </Text>
      )}
      <Switch
        style={switchStyle}
        onValueChange={onValueChange}
        value={value}
        {...switchProps}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  row: {
    alignItems: 'center',
    flexDirection: 'row',
  },
  label: {
    color: Colors.TEXT_COLOR_PRIMARY,
    flex: 1,
    fontSize: 14,
    fontWeight: Fonts.FONT_WEIGHT_REGULAR,
    marginRight: 8,
    textAlign: 'left',
  },
});
