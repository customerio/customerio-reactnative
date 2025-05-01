import { Colors } from '@colors';
import React from 'react';
import { StyleSheet, TextInput, View } from 'react-native';
import { systemWeights } from 'react-native-typography';
import { BoldText } from './text';
interface TextFieldProps extends React.ComponentProps<typeof TextInput> {
  label: string;
  footnote?: string;
}

export const TextField = ({ label, ...props }: TextFieldProps) => {
  return (
    <View style={styles.container}>
      <BoldText style={styles.label}>{label}</BoldText>
      <TextInput style={styles.input} editable multiline {...props} />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
  },

  label: {
    marginEnd: 8,
  },

  input: {
    borderBottomWidth: 1,
    borderBottomColor: Colors.secondaryBg,
    color: Colors.bodyText,
    flex: 1,
    ...systemWeights.regular,
  },
});
