import React, { useEffect } from 'react';
import { Text, View } from 'react-native';
import { CioRegion, CustomerIO } from 'customerio-reactnative';

export default function App(): React.JSX.Element {
  useEffect(() => {
    CustomerIO.initialize({
      cdpApiKey: 'scene-validation-key',
      region: CioRegion.US,
    });
  }, []);

  return (
    <View>
      <Text>Customer.io React Native scene validation</Text>
    </View>
  );
}
