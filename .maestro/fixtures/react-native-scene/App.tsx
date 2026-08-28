import React, { useEffect, useState } from 'react';
import { Linking, Settings, Text, View } from 'react-native';
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
  const routingMode =
    Settings.get('CioSceneE2EPersistedMode') === 'linking'
      ? 'linking'
      : 'acknowledged';
  const [receivedUrl, setReceivedUrl] = useState<string | null>(null);
  const [declineCount, setDeclineCount] = useState(0);
  const [initialized, setInitialized] = useState(false);
  const [failure, setFailure] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    let subscription: { remove(): void } | undefined;

    const initialize = async () => {
      if (routingMode === 'linking') {
        subscription = Linking.addEventListener('url', ({ url }) => {
          setReceivedUrl(url);
        });
        CustomerIO.setDeepLinkRoutingReady();
      }

      await CustomerIO.initialize({
        cdpApiKey: 'scene-e2e-key',
        region: CioRegion.US,
      });

      // Register after initialization in acknowledged mode. This intentionally exercises the cold
      // replay boundary where initialization must not drain the URL into legacy Linking.
      if (routingMode === 'acknowledged') {
        const handlerSubscription = CustomerIO.setDeepLinkHandler((url) => {
          if (url === 'cio-rn-scene-e2e://declined') {
            setDeclineCount((count) => count + 1);
            return false;
          }
          setReceivedUrl(url);
          return true;
        });
        if (!active) {
          handlerSubscription.remove();
          return;
        }
        subscription = handlerSubscription;
      }

      const status =
        await CustomerIO.pushMessaging.showPromptForPushNotifications({
          ios: { sound: true, badge: true },
        });
      if (status !== CioPushPermissionStatus.Granted) {
        throw new Error(`Push permission is ${status}`);
      }
      await validateLiveActivityBridge();
      setInitialized(true);
    };

    initialize().catch((error: unknown) => {
      if (active) {
        setFailure(error instanceof Error ? error.message : String(error));
      }
    });

    return () => {
      active = false;
      subscription?.remove();
    };
  }, [routingMode]);

  return (
    <View>
      <Text>
        Customer.io React Native scene E2E{' '}
        {initialized ? 'ready' : 'initializing'}
      </Text>
      <Text>Routing: {routingMode}</Text>
      {failure && <Text>Initialization failed: {failure}</Text>}
      {receivedUrl && <Text>Received: {receivedUrl}</Text>}
      {declineCount > 0 && <Text>Declined count: {declineCount}</Text>}
    </View>
  );
}
