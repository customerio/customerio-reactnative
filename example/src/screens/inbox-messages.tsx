import { NavigationScreenProps } from '@navigation';
import { CustomerIO, InboxMessage } from 'customerio-reactnative';
import React, { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  FlatList,
  Modal,
  RefreshControl,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { showMessage } from 'react-native-flash-message';

export const InboxMessagesScreen = ({
  navigation,
}: NavigationScreenProps<'Inbox Messages'>) => {
  const [messages, setMessages] = useState<InboxMessage[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [showTrackModal, setShowTrackModal] = useState(false);
  const [selectedMessage, setSelectedMessage] = useState<InboxMessage | null>(
    null
  );
  const [actionNameInput, setActionNameInput] = useState('');
  const inbox = CustomerIO.inAppMessaging.inbox();

  useEffect(() => {
    // Subscribe to inbox updates
    const subscription = inbox.subscribeToMessages({
      onMessagesChanged: (updatedMessages) => {
        setMessages(updatedMessages);
        setLoading(false);
        setRefreshing(false);
      },
    });

    // Get initial messages
    getMessages();

    // Clean up subscription on unmount
    return () => {
      subscription.remove();
    };
  }, []);

  const getMessages = async () => {
    try {
      setLoading(true);
      const fetchedMessages = await inbox.getMessages();
      setMessages(fetchedMessages);
    } catch (error) {
      console.error('Failed to get messages:', error);
      showMessage({
        message: 'Failed to get inbox messages',
        type: 'danger',
      });
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const handleRefresh = () => {
    setRefreshing(true);
    getMessages();
  };

  const handleToggleRead = (message: InboxMessage) => {
    if (message.opened) {
      inbox.markMessageUnopened(message);
      showMessage({
        message: 'Message marked as unread',
        type: 'info',
      });
    } else {
      inbox.markMessageOpened(message);
      showMessage({
        message: 'Message marked as read',
        type: 'success',
      });
    }
  };

  const handleTrackClick = (message: InboxMessage) => {
    setSelectedMessage(message);
    setActionNameInput('');
    setShowTrackModal(true);
  };

  const submitTrackClick = () => {
    if (!selectedMessage) return;

    const actionName = actionNameInput.trim();
    inbox.trackMessageClicked(
      selectedMessage,
      actionName.length > 0 ? actionName : undefined
    );

    showMessage({
      message: actionName
        ? `Click tracked with action: ${actionName}`
        : 'Click tracked successfully',
      type: 'success',
    });

    setShowTrackModal(false);
    setSelectedMessage(null);
    setActionNameInput('');
  };

  const handleDelete = (message: InboxMessage) => {
    Alert.alert(
      'Delete Message',
      'Are you sure you want to delete this message?',
      [
        {
          text: 'Cancel',
          style: 'cancel',
        },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: () => {
            inbox.markMessageDeleted(message);
            showMessage({
              message: 'Message deleted',
              type: 'success',
            });
          },
        },
      ]
    );
  };

  const formatDateTime = (timestamp: number) => {
    const date = new Date(timestamp);
    return date.toLocaleString();
  };

  const renderMessage = ({
    item,
    index,
  }: {
    item: InboxMessage;
    index: number;
  }) => {
    const sentDateTime = formatDateTime(item.sentAt);
    const expiryDateTime = item.expiry ? formatDateTime(item.expiry) : null;
    const hasProperties = Object.keys(item.properties).length > 0;

    return (
      <View style={[styles.messageCard, item.opened && styles.messageOpened]}>
        <View style={styles.messageHeaderRow}>
          <View style={styles.messageHeaderLeft}>
            <Text style={styles.messageIndex}>#{index + 1}</Text>
            <Text style={styles.messageType}>{item.type}</Text>
          </View>
          <View style={styles.badgesRow}>
            {item.priority !== undefined && (
              <View style={styles.priorityBadge}>
                <Text style={styles.priorityText}>P{item.priority}</Text>
              </View>
            )}
            {item.opened ? (
              <View style={styles.badge}>
                <Text style={styles.badgeText}>READ</Text>
              </View>
            ) : (
              <View style={[styles.badge, styles.badgeUnread]}>
                <Text style={[styles.badgeText, styles.badgeTextUnread]}>
                  UNREAD
                </Text>
              </View>
            )}
          </View>
        </View>

        <View style={styles.messageIds}>
          <Text style={styles.messageId}>{item.queueId}</Text>
          {item.deliveryId && (
            <Text style={styles.messageId}>{item.deliveryId}</Text>
          )}
        </View>

        <View style={styles.messageInfo}>
          <Text style={styles.label}>Sent: {sentDateTime}</Text>
          {expiryDateTime && (
            <Text style={styles.label}>Expires: {expiryDateTime}</Text>
          )}
        </View>

        {item.topics.length > 0 && (
          <View style={styles.topicsContainer}>
            <Text style={styles.label}>Topics: </Text>
            {item.topics.map((topic, index) => (
              <View key={`${topic}-${index}`} style={styles.topicBadge}>
                <Text style={styles.topicText}>{topic}</Text>
              </View>
            ))}
          </View>
        )}

        {hasProperties && (
          <View style={styles.propertiesContainer}>
            <Text style={styles.propertiesText}>
              {JSON.stringify(item.properties, null, 2)}
            </Text>
          </View>
        )}

        <View style={styles.actionsContainer}>
          <TouchableOpacity
            style={styles.actionButton}
            onPress={() => handleToggleRead(item)}
          >
            <Text style={styles.actionText}>
              {item.opened ? 'Unread' : 'Read'}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.actionButton}
            onPress={() => handleTrackClick(item)}
          >
            <Text style={styles.actionText}>Track</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.actionButton, styles.deleteButton]}
            onPress={() => handleDelete(item)}
          >
            <Text style={[styles.actionText, styles.deleteText]}>Delete</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  };

  if (loading && messages.length === 0) {
    return (
      <View style={styles.centerContainer}>
        <ActivityIndicator size="large" />
        <Text style={styles.loadingText}>Loading messages...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <FlatList
        data={messages}
        renderItem={renderMessage}
        keyExtractor={(item) => item.queueId}
        contentContainerStyle={styles.listContainer}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />
        }
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyText}>📬</Text>
            <Text style={styles.emptyText}>No messages in your inbox</Text>
            <Text style={styles.emptySubtext}>
              Pull down to refresh
            </Text>
          </View>
        }
      />

      <Modal
        visible={showTrackModal}
        transparent
        animationType="fade"
        onRequestClose={() => setShowTrackModal(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>Track Click</Text>
            <Text style={styles.modalDescription}>
              Enter an optional action name:
            </Text>
            <TextInput
              style={styles.modalInput}
              placeholder="Action name (optional)"
              value={actionNameInput}
              onChangeText={setActionNameInput}
              autoFocus
            />
            <View style={styles.modalButtons}>
              <TouchableOpacity
                style={[styles.modalButton, styles.modalButtonCancel]}
                onPress={() => setShowTrackModal(false)}
              >
                <Text style={styles.modalButtonCancelText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalButton, styles.modalButtonTrack]}
                onPress={submitTrackClick}
              >
                <Text style={styles.modalButtonText}>Track</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  centerContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 16,
    fontSize: 16,
    color: '#666',
  },
  listContainer: {
    padding: 16,
    gap: 12,
  },
  messageCard: {
    backgroundColor: '#fff',
    borderRadius: 8,
    padding: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  messageOpened: {
    backgroundColor: '#e8e8e8',
  },
  messageHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 4,
  },
  messageHeaderLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  messageIndex: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#333',
  },
  messageType: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
  },
  badgesRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  messageIds: {
    marginBottom: 4,
  },
  messageId: {
    fontSize: 12,
    color: '#888',
    fontFamily: 'monospace',
  },
  messageInfo: {
    marginBottom: 12,
  },
  priorityBadge: {
    backgroundColor: '#FF9800',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 4,
  },
  priorityText: {
    fontSize: 12,
    fontWeight: 'bold',
    color: '#fff',
  },
  badge: {
    backgroundColor: '#757575',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 4,
  },
  badgeUnread: {
    backgroundColor: '#2196F3',
  },
  badgeText: {
    fontSize: 12,
    fontWeight: 'bold',
    color: '#fff',
  },
  badgeTextUnread: {
    color: '#fff',
  },
  label: {
    fontSize: 14,
    color: '#666',
    marginBottom: 4,
  },
  topicsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    alignItems: 'center',
    marginBottom: 12,
  },
  topicBadge: {
    backgroundColor: '#f0f0f0',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 4,
    marginRight: 4,
    marginBottom: 4,
  },
  topicText: {
    fontSize: 12,
    color: '#333',
  },
  propertiesContainer: {
    marginBottom: 12,
    padding: 8,
    borderRadius: 4,
    borderWidth: 1,
    borderColor: '#d0d0d0',
  },
  propertiesText: {
    fontSize: 12,
    color: '#555',
    fontFamily: 'monospace',
  },
  actionsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 8,
  },
  actionButton: {
    flex: 1,
    backgroundColor: '#2196F3',
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 4,
    alignItems: 'center',
  },
  deleteButton: {
    backgroundColor: '#f44336',
  },
  actionText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '600',
  },
  deleteText: {
    color: '#fff',
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 64,
  },
  emptyText: {
    fontSize: 16,
    color: '#666',
    marginBottom: 8,
  },
  emptySubtext: {
    fontSize: 14,
    color: '#999',
    textAlign: 'center',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 20,
    width: '85%',
    maxWidth: 400,
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 8,
    color: '#333',
  },
  modalDescription: {
    fontSize: 14,
    color: '#666',
    marginBottom: 16,
  },
  modalInput: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    marginBottom: 20,
  },
  modalButtons: {
    flexDirection: 'row',
    gap: 12,
  },
  modalButton: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  modalButtonCancel: {
    backgroundColor: '#f5f5f5',
  },
  modalButtonCancelText: {
    color: '#666',
    fontSize: 16,
    fontWeight: '600',
  },
  modalButtonTrack: {
    backgroundColor: '#2196F3',
  },
  modalButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});
