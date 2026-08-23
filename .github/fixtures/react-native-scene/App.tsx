import React, { useEffect } from 'react';
import { Linking, Text, View } from 'react-native';
import { CioRegion, CustomerIO } from 'customerio-reactnative';

export default function App(): React.JSX.Element {
  useEffect(() => {
    const subscription = Linking.addEventListener('url', ({ url }) => {
      if (url === 'https://customer.io/react-native-scene-validation') {
        Linking.openURL('cio-rn-scene-validation://warm-received');
      }
    });

    CustomerIO.initialize({
      cdpApiKey: 'scene-validation-key',
      region: CioRegion.US,
    });

    Linking.getInitialURL().then((url) => {
      if (url === 'cio-rn-scene-validation://cold') {
        return Linking.openURL('cio-rn-scene-validation://cold-received');
      }
      return undefined;
    });

    return () => subscription.remove();
  }, []);

  return (
    <View>
      <Text>Customer.io React Native scene validation</Text>
    </View>
  );
}
