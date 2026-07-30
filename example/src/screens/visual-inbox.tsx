import { NavigationScreenProps } from '@navigation';
import {
  CustomerIO,
  InboxEventType,
  NotificationInboxBellView,
  NotificationInboxView,
} from 'customerio-reactnative';
import React, { useEffect } from 'react';
import { Linking, StyleSheet, Text, View } from 'react-native';
import { showMessage } from 'react-native-flash-message';

/**
 * Demonstrates the two native Visual Notification Inbox UI components exposed by the SDK:
 *
 * 1. NotificationInboxBellView — the branded bell; tapping it opens the SDK's own inbox panel.
 * 2. NotificationInboxView     — the Jist-rendered message list, placed by this screen.
 *
 * The host places both wherever it likes; the SDK owns the panel and all rendering.
 *
 * Message actions are handled by the global InboxEventListener (configured elsewhere), so these
 * components take no per-message action callbacks.
 */
export const VisualInboxScreen = ({}: NavigationScreenProps<'Visual Inbox'>) => {

  // Register a global inbox event listener while this screen is mounted.
  // While registered, the host (this app) owns action navigation: the native
  // SDK forwards taps here and suppresses its default handling.
  useEffect(() => {
    const subscription = CustomerIO.inAppMessaging.registerInboxEventListener(
      (event) => {
        switch (event.eventType) {
          case InboxEventType.messageActionTaken:
            showMessage({
              message: `Inbox action taken: ${event.actionName ?? ''} -> ${
                event.actionValue ?? ''
              }`,
              type: 'success',
            });
            // While a listener is registered the SDK suppresses its own deep-link handling and
            // treats the action as host-handled, so nothing navigates unless the host does it.
            // Hand the value to the OS exactly as the SDK would: our own scheme round-trips back
            // through the NavigationContainer `linking` config, anything else opens externally.
            if (event.actionValue) {
              Linking.openURL(event.actionValue).catch((error) => {
                showMessage({
                  message: `Could not open ${event.actionValue}`,
                  type: 'danger',
                });
                // eslint-disable-next-line no-console
                console.warn('Failed to open inbox action deep link', error);
              });
            }
            break;
          case InboxEventType.messageShown:
            showMessage({ message: 'Inbox message shown', type: 'info' });
            break;
          case InboxEventType.messageOpened:
            showMessage({ message: 'Inbox message opened', type: 'info' });
            break;
          case InboxEventType.messageDismissed:
            showMessage({ message: 'Inbox message dismissed', type: 'info' });
            break;
        }
        // eslint-disable-next-line no-console
        console.log('Inbox event received', event.eventType, event.message);
      }
    );

    return () => {
      subscription.remove();
    };
  }, []);

  return (
    <View style={styles.root}>
      {/*
        Deliberately NOT a ScrollView. NotificationInboxView scrolls its own message list, and a parent
        ScrollView intercepts the vertical drag before the native list sees it. These components are
        meant to own their screen (or a fixed region of one), not to sit in a scrolling page.
      */}
      <View style={styles.content}>
        {/* 1. Branded bell — tapping it opens the SDK's inbox panel. Host owns placement. */}
        <View style={styles.bellRow}>
          <Text style={styles.sectionTitle}>NotificationInboxBellView</Text>
          <NotificationInboxBellView
            style={styles.bell}
            onTap={() => {
              // Observational only: the SDK is already opening its panel.
              showMessage({ message: 'Bell tapped', type: 'info' });
            }}
          />
        </View>
        <Text style={styles.sectionBody}>
          Tapping the bell opens the SDK's inbox panel — this screen presents nothing.
        </Text>

        {/* 2. The message list, placed inline by this screen. */}
        <Text style={styles.sectionTitle}>NotificationInboxView</Text>
        <Text style={styles.sectionBody}>
          The Jist-rendered message list, filling the rest of the screen.
        </Text>
        <View style={styles.embeddedList}>
          <NotificationInboxView style={styles.fill} />
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#f5f5f5' },
  content: { flex: 1, padding: 16, gap: 8 },
  fill: { flex: 1 },
  sectionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
    marginTop: 12,
  },
  sectionBody: { fontSize: 13, color: '#666', marginBottom: 4 },
  bellRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 8,
  },
  // 88 not 56: the native composition insets the 56dp bell by 16 on each side, so a
  // 56-square box squeezes the circle down onto the glyph.
  bell: { width: 88, height: 88 },
  embeddedList: {
    flex: 1,
    backgroundColor: '#fff',
    borderRadius: 8,
    overflow: 'hidden',
  },
});
