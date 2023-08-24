import React from 'react';
import ReactNative, { StyleSheet, Switch, View } from 'react-native';
import * as Colors from '../constants/Colors';
import * as Fonts from '../constants/Fonts';
import { Text } from './Text';

interface SwitchButtonProps {
  value: any;
  label: string;
  contentDesc?: string;
  onValueChange: (value: boolean) => Promise<void> | void;
  style?: ReactNative.StyleProp<ReactNative.ViewStyle>;
  labelStyle?: ReactNative.StyleProp<ReactNative.TextStyle>;
  labelProps?: ReactNative.TextProps;
  switchStyle?: ReactNative.StyleProp<ReactNative.ViewStyle>;
  switchProps?: ReactNative.SwitchProps;
}

export const SwitchField: React.FC<SwitchButtonProps> = ({
  value,
  label,
  contentDesc,
  onValueChange,
  style,
  labelStyle,
  labelProps,
  switchStyle,
  switchProps,
  ...props
}) => {
  // Helps increase the touchable area of the switch
  const switchHitSlopDefault = 6;
  const hitSlop: ReactNative.Insets = {
    top: switchHitSlopDefault,
    left: switchHitSlopDefault,
    bottom: switchHitSlopDefault,
    right: switchHitSlopDefault,
  };

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
        accessibilityLabel={contentDesc}
        trackColor={{
          false: Colors.SWITCH_TRACK_COLOR_OFF,
          true: Colors.SWITCH_TRACK_COLOR_ON,
        }}
        thumbColor={
          value ? Colors.SWITCH_THUMB_COLOR_ON : Colors.SWITCH_THUMB_COLOR_OFF
        }
        ios_backgroundColor={Colors.SWITCH_TRACK_COLOR_OFF}
        hitSlop={hitSlop}
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
