import { type EventSubscription } from 'react-native';
import { NativeLoggerListener } from './native-logger-listener';
import type { Spec as CodegenSpec } from './specs/modules/NativeCustomerIOMessagingInApp';
import NativeCustomerIOMessagingInApp from './specs/modules/NativeCustomerIOMessagingInApp';
import type { InboxMessage, NotificationInboxChangeListener } from './types';
import { callNativeModule, ensureNativeModule } from './utils/native-bridge';

// Reference to the native CustomerIO In-App Messaging module
const nativeModule = ensureNativeModule(NativeCustomerIOMessagingInApp);

// Wrapper function that ensures SDK is initialized before calling native methods
const withNativeModule = <R>(fn: (native: CodegenSpec) => R): R => {
  return callNativeModule(nativeModule, fn);
};

/**
 * Public API methods for NotificationInbox.
 * Define the TypeScript API here with proper types (InboxMessage instead of UnsafeObject).
 *
 * @internal
 */
interface NotificationInboxPublicSpec {
  getMessages(topic?: string): Promise<InboxMessage[]>;
  subscribeToMessages(
    listener: NotificationInboxChangeListener,
    topic?: string
  ): EventSubscription;
  markMessageOpened(message: InboxMessage): void;
  markMessageUnopened(message: InboxMessage): void;
  markMessageDeleted(message: InboxMessage): void;
  trackMessageClicked(message: InboxMessage, actionName?: string): void;
}

/**
 * Native inbox methods from CodegenSpec that should be excluded from CustomerIOInAppMessaging.
 * Includes both public methods (in NotificationInboxPublicSpec) and internal methods.
 *
 * @internal
 */
export type NotificationInboxSpec =
  | keyof NotificationInboxPublicSpec
  | 'subscribeToMessagesChanged'
  | 'setupInboxListener';

/**
 * Helper function to parse raw inbox message from native layer
 * @internal
 */
function parseInboxMessage(raw: any): InboxMessage {
  return {
    queueId: raw.queueId,
    deliveryId: raw.deliveryId ?? undefined,
    expiry: raw.expiry ?? undefined,
    sentAt: raw.sentAt,
    topics: raw.topics || [],
    type: raw.type,
    opened: raw.opened,
    priority: raw.priority ?? undefined,
    properties: raw.properties || {},
  };
}

/**
 * Manages inbox messages for the current user.
 *
 * @public
 */
export class NotificationInbox implements NotificationInboxPublicSpec {
  /**
   * Gets inbox messages.
   */
  async getMessages(topic?: string): Promise<InboxMessage[]> {
    return withNativeModule(async (native) => {
      const rawMessages = await native.getMessages(topic);
      return rawMessages.map(parseInboxMessage);
    });
  }

  /**
   * Subscribes to inbox message changes.
   * Optionally filter messages by topic.
   */
  subscribeToMessages(
    listener: NotificationInboxChangeListener,
    topic?: string
  ): EventSubscription {
    const emitter = (data: any) => {
      let messages = (data.messages || []).map(parseInboxMessage);

      // Filter by topic if specified (case-insensitive)
      if (topic) {
        const topicLower = topic.toLowerCase();
        messages = messages.filter((msg: InboxMessage) =>
          msg.topics.some((t) => t.toLowerCase() === topicLower)
        );
      }

      listener.onMessagesChanged(messages);
    };

    return withNativeModule((native) => {
      try {
        // Set up the native inbox listener before subscribing to events
        // This will automatically trigger onMessagesChanged with current messages
        native.setupInboxListener();

        // Register TurboModule event listener and return subscription
        return native.subscribeToMessagesChanged(emitter);
      } catch (error) {
        NativeLoggerListener.warn(
          'Failed to attach inbox change listener:',
          error
        );
        // Return a no-op subscription to maintain backwards compatibility
        return {
          remove: () => {},
          eventType: '',
          key: 0,
          subscriber: null as any,
        } as EventSubscription;
      }
    });
  }

  /**
   * Marks an inbox message as opened/read.
   */
  markMessageOpened(message: InboxMessage) {
    withNativeModule((native) => native.markMessageOpened(message));
  }

  /**
   * Marks an inbox message as unopened/unread.
   */
  markMessageUnopened(message: InboxMessage) {
    withNativeModule((native) => native.markMessageUnopened(message));
  }

  /**
   * Marks an inbox message as deleted.
   */
  markMessageDeleted(message: InboxMessage) {
    withNativeModule((native) => native.markMessageDeleted(message));
  }

  /**
   * Tracks a click event for an inbox message.
   */
  trackMessageClicked(message: InboxMessage, actionName?: string) {
    withNativeModule((native) =>
      native.trackMessageClicked(message, actionName)
    );
  }
}
