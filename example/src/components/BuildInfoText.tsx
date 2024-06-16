import React, { useEffect, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { getBuildNumber, getVersion } from 'react-native-device-info';
import { SmallFootnote } from './text';

export const BuildInfoText = () => {
  const [buildInfo, setBuildInfo] = useState('');

  useEffect(() => {
    const sdkPackageJson = require('customerio-reactnative/package.json');

    const value =
      `Customer.io` +
      ` React Native SDK ${sdkPackageJson.version}` +
      ` Sample App ${getVersion()} (${getBuildNumber()})`;
    setBuildInfo(value);
  }, [buildInfo]);

  return (
    <View style={styles.container}>
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
});

export default BuildInfoText;
