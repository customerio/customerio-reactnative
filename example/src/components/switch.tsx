import { Colors } from '@colors';
import React from 'react';
import {
  Switch as RNSwitch,
  StyleSheet,
  SwitchProps,
  View,
} from 'react-native';
import { BoldText } from './text';

interface Props extends SwitchProps {
  label?: string;
}

export const Switch = ({ label, ...props }: Props) => {
  return (
    <View style={styles.container}>
      {label && <BoldText>{label}</BoldText>}
      <RNSwitch
        thumbColor={Colors.primaryText}
        trackColor={{
          true: Colors.primaryBg,
          false: Colors.secondaryBg,
        }}
        {...props}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignContent: 'flex-end',
    flexWrap: 'wrap',
    gap: 16,
  },
});
