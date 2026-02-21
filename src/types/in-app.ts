/**
 * In-app message data structure for event callbacks.
 *
 * Contains metadata about displayed in-app messages that can be used
 * for tracking user interactions and message performance analytics.
 *
 * @public
 */
export interface InAppMessage {
  /** Unique identifier for the message template */
  messageId: string;
  /** Unique identifier for this specific message delivery */
  deliveryId?: string;
  /** Element ID for inline message UI component that was interacted with */
  elementId?: string;
}

/**
 * Enum to represent the type of event triggered by in-app event callback.
 *
 * @public
 */
export enum InAppMessageEventType {
  errorWithMessage = 'errorWithMessage',
  messageActionTaken = 'messageActionTaken',
  messageDismissed = 'messageDismissed',
  messageShown = 'messageShown',
}

/**
 * Represents an inbox message for a user.
 *
 * Inbox messages are persistent messages that can be displayed in a message center or inbox UI.
 * They support read/unread states, expiration, and custom properties.
 *
 * @public
 */
export interface InboxMessage {
  /** Internal queue identifier (for SDK use) */
  queueId: string;
  /** Unique identifier for this message delivery */
  deliveryId?: string;
  /** Expiration date for the message. Messages may be hidden after this date. */
  expiry?: number;
  /** Date when the message was sent (Unix timestamp in milliseconds) */
  sentAt: number;
  /** List of topic identifiers associated with this message */
  topics: string[];
  /** Message type identifier */
  type: string;
  /** Whether the user has opened/read this message */
  opened: boolean;
  /** Priority for message ordering. Lower values = higher priority (e.g., 1 is higher priority than 100) */
  priority?: number;
  /** Custom key-value properties associated with this message */
  properties: Record<string, any>;
}

/**
 * Listener for notification inbox message changes.
 *
 * Receives real-time notifications when inbox messages are added, updated, or removed.
 * Callbacks are invoked on the main thread for safe UI updates.
 *
 * @public
 */
export type NotificationInboxChangeListener = {
  onMessagesChanged: (messages: InboxMessage[]) => void;
};
