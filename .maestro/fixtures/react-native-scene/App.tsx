import React, { useEffect, useState } from 'react';
import { Text, View } from 'react-native';
import {
  CioPushPermissionStatus,
  CioRegion,
  CustomerIO,
} from 'customerio-reactnative';

async function validateLiveActivityBridge(): Promise<void> {
  const invalidUrl = 'https://[invalid';
  const passthrough =
    await CustomerIO.liveActivities.handleWidgetUrl(invalidUrl);
  if (passthrough !== invalidUrl) {
    throw new Error('Live Activity bridge changed an invalid URL');
  }

  const destinationless = await CustomerIO.liveActivities.handleWidgetUrl(
    'cio-live-activity://open?cio_delivery_id=scene-e2e-delivery'
  );
  if (destinationless !== null) {
    throw new Error(
      'Live Activity bridge did not map NSNull to JavaScript null'
    );
  }
}

export default function App(): React.JSX.Element {
  const [receivedUrl, setReceivedUrl] = useState<string | null>(null);
  const [initialized, setInitialized] = useState(false);
  const [failure, setFailure] = useState<string | null>(null);

  useEffect(() => {
    const subscription = CustomerIO.setDeepLinkHandler((url) => {
      setReceivedUrl(url);
      return true;
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
      .then(async (status) => {
        if (status !== CioPushPermissionStatus.Granted) {
          throw new Error(`Push permission is ${status}`);
        }
        await validateLiveActivityBridge();
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
