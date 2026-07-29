import { NavigationScreenProps } from '@navigation';
import {
  CustomerIO,
  InboxEventType,
  NotificationInboxBellView,
  NotificationInboxOverlayView,
  NotificationInboxView,
} from 'customerio-reactnative';
import React, { useEffect, useState } from 'react';
import {
  Modal,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { showMessage } from 'react-native-flash-message';

/**
 * Demonstrates the three native Visual Notification Inbox UI components exposed by the SDK:
 *
 * 1. NotificationInboxOverlayView — drop-in floating bell + slide-out panel.
 * 2. NotificationInboxBellView    — just the bell; this screen opens its own modal.
 * 3. NotificationInboxView        — the Jist-rendered message list embedded inline.
 *
 * Message actions are handled by the global InboxEventListener (configured elsewhere), so these
 * components take no per-message action callbacks.
 */
export const VisualInboxScreen = ({}: NavigationScreenProps<'Visual Inbox'>) => {
  const [showBellModal, setShowBellModal] = useState(false);

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
      <ScrollView contentContainerStyle={styles.content}>
        {/* 2. Bell only — host presents its own UI on tap. */}
        <Text style={styles.sectionTitle}>NotificationInboxBellView</Text>
        <Text style={styles.sectionBody}>
          Just the bell. Tapping it opens a modal hosting the message list.
        </Text>
        <View style={styles.bellRow}>
          <NotificationInboxBellView
            style={styles.bell}
            onTap={() => {
              showMessage({ message: 'Bell tapped', type: 'info' });
              setShowBellModal(true);
            }}
          />
        </View>

        {/* 3. Embedded message list. */}
        <Text style={styles.sectionTitle}>NotificationInboxView</Text>
        <Text style={styles.sectionBody}>
          The Jist-rendered message list embedded directly in this screen.
        </Text>
        <View style={styles.embeddedList}>
          <NotificationInboxView style={styles.fill} />
        </View>
      </ScrollView>

      {/* 1. Drop-in overlay (floating bell + slide-out panel) layered over the whole screen. */}
      <NotificationInboxOverlayView
        style={StyleSheet.absoluteFill}
        pointerEvents="box-none"
      />

      {/* Modal opened by the standalone bell. */}
      <Modal
        visible={showBellModal}
        animationType="slide"
        onRequestClose={() => setShowBellModal(false)}
      >
        <View style={styles.modalRoot}>
          <View style={styles.modalHeader}>
            <Text style={styles.modalTitle}>Inbox</Text>
            <TouchableOpacity onPress={() => setShowBellModal(false)}>
              <Text style={styles.modalClose}>Close</Text>
            </TouchableOpacity>
          </View>
          <NotificationInboxView style={styles.fill} />
        </View>
      </Modal>
    </View>
  );
};

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#f5f5f5' },
  content: { padding: 16, gap: 8 },
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
    justifyContent: 'flex-end',
    paddingVertical: 8,
  },
  bell: { width: 56, height: 56 },
  embeddedList: {
    height: 360,
    backgroundColor: '#fff',
    borderRadius: 8,
    overflow: 'hidden',
  },
  modalRoot: { flex: 1, backgroundColor: '#fff' },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#ddd',
  },
  modalTitle: { fontSize: 18, fontWeight: 'bold', color: '#333' },
  modalClose: { fontSize: 16, color: '#2196F3', fontWeight: '600' },
});
