import React, { useEffect, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { getBuildNumber, getVersion } from 'react-native-device-info';
import { useThemeContext } from '../../theme';

const BuildInfoText = () => {
  const theme = useThemeContext();

  const styles = StyleSheet.create({
    buildInfoContainer: {
      alignItems: 'center',
      justifyContent: 'center',
      paddingHorizontal: 16,
      marginBottom: 32,
    },
    buildInfoText: {
      ...theme.styles.text,
      fontSize: 12,
      fontWeight: '400',
      alignSelf: 'center',
      textAlign: 'center',
    },
  });

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

export default BuildInfoText;
