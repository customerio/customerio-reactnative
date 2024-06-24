import { ScreensContext } from '@screens-context';
import React, { useContext, useEffect, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { systemWeights } from 'react-native-typography';
import { SmallFootnote } from './text';

export const BuildInfoText = () => {
  const [buildInfo, setBuildInfo] = useState('');
  const { moduleName } = useContext(ScreensContext);
  useEffect(() => {
    const sdkPackageJson = require('customerio-reactnative/package.json');

    const value = `Customer.io` + ` SDK version ${sdkPackageJson.version}`;
    setBuildInfo(value);
  }, [buildInfo]);

  return (
    <View style={styles.container}>
      <SmallFootnote>
        Running the
        <SmallFootnote style={styles.flavorText}>
          {' '}
          {moduleName}
        </SmallFootnote>{' '}
        App
      </SmallFootnote>
      <SmallFootnote>{buildInfo}</SmallFootnote>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
    marginVertical: 16,
  },

  flavorText: {
    ...systemWeights.bold,
  },
});

export default BuildInfoText;
