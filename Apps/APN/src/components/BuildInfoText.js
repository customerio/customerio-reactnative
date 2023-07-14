import React, { useEffect, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { getBuildNumber, getVersion } from 'react-native-device-info';
import * as Colors from '../constants/Colors';
import * as Fonts from '../constants/Fonts';

const BuildInfoText = () => {
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
    <View style={styles.buildInfoContainer}>
      <Text style={styles.buildInfoText}>{buildInfo}</Text>
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
  buildInfoText: {
    alignSelf: 'center',
    color: Colors.TEXT_COLOR_PRIMARY,
    fontSize: 12,
    fontWeight: '400',
    textAlign: 'center',
  },
});

export default BuildInfoText;
