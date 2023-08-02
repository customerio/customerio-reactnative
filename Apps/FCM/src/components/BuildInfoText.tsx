import React, { useEffect, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { getBuildNumber, getVersion } from 'react-native-device-info';
import { Caption } from './Text';

const BuildInfoText: React.FC = () => {
  const [buildInfo, setBuildInfo] = useState('');

  useEffect(() => {
    const sdkPackageJson = require('customerio-reactnative/package.json');

    const value =
      'Customer.io' +
      ` React Native SDK ${sdkPackageJson.version}` +
      ` APN Sample ${getVersion()} (${getBuildNumber()})`;
    setBuildInfo(value);
  }, [buildInfo]);

  return (
    <View style={styles.buildInfoContainer}>
      <Caption>{buildInfo}</Caption>
    </View>
  );
};

const styles = StyleSheet.create({
  buildInfoContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 32,
    paddingHorizontal: 16,
  },
});

export default BuildInfoText;
