import React from 'react';
import { StyleSheet, View } from 'react-native';
import { BuildMetadata } from '../utils/build';
import { Caption } from './Text';

const BuildInfoText = () => {
  const metadata = BuildMetadata.toString();

  return (
    <View style={styles.buildInfoContainer}>
      <Caption style={styles.buildInfoText}>{metadata}</Caption>
    </View>
  );
};

const styles = StyleSheet.create({
  buildInfoContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
    paddingHorizontal: 16,
  },
  buildInfoText: {
    width: '100%',
    textAlign: 'left',
  },
});

export default BuildInfoText;
