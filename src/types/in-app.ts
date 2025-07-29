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
