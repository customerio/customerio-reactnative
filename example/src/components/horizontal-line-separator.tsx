import { Colors } from '@colors';
import React from 'react';
import { StyleSheet, View } from 'react-native';

export const HorizontalLineSeparator = () => <View style={styles.separator} />;

const styles = StyleSheet.create({
  separator: {
    marginVertical: 8,
    borderBottomColor: Colors.bodyText,
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
});
