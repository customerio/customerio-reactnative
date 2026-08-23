import React, { useEffect } from 'react';
import { Linking, Text, View } from 'react-native';
import { CioRegion, CustomerIO } from 'customerio-reactnative';

export default function App(): React.JSX.Element {
  useEffect(() => {
    const subscription = Linking.addEventListener('url', ({ url }) => {
      if (url === 'https://customer.io/react-native-scene-validation') {
        Linking.openURL('cio-rn-scene-validation://received');
      }
    });

    CustomerIO.initialize({
      cdpApiKey: 'scene-validation-key',
      region: CioRegion.US,
    });

    return () => subscription.remove();
  }, []);

  return (
    <View>
      <Text>Customer.io React Native scene validation</Text>
    </View>
  );
}
