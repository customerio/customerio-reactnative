import React, { useEffect, useState } from 'react';
import { Linking, Text, View } from 'react-native';
import {
  CioPushPermissionStatus,
  CioRegion,
  CustomerIO,
} from 'customerio-reactnative';

export default function App(): React.JSX.Element {
  const [receivedUrl, setReceivedUrl] = useState<string | null>(null);
  const [initialized, setInitialized] = useState(false);
  const [failure, setFailure] = useState<string | null>(null);

  useEffect(() => {
    const subscription = Linking.addEventListener('url', ({ url }) => {
      setReceivedUrl(url);
    });

    CustomerIO.initialize({
      cdpApiKey: 'scene-e2e-key',
      region: CioRegion.US,
    })
      .then(() =>
        CustomerIO.pushMessaging.showPromptForPushNotifications({
          ios: { sound: true, badge: true },
        })
      )
      .then((status) => {
        if (status !== CioPushPermissionStatus.Granted) {
          throw new Error(`Push permission is ${status}`);
        }
        setInitialized(true);
      })
      .catch((error: unknown) => {
        setFailure(error instanceof Error ? error.message : String(error));
      });

    return () => subscription.remove();
  }, []);

  return (
    <View>
      <Text>
        Customer.io React Native scene E2E{' '}
        {initialized ? 'ready' : 'initializing'}
      </Text>
      {failure && <Text>Initialization failed: {failure}</Text>}
      {receivedUrl && <Text>Received: {receivedUrl}</Text>}
    </View>
  );
}
