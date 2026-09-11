import type { InboxMessage } from './in-app';

/**
 * Enum representing the type of event triggered by an inbox event callback.
 *
 * Mirrors the native `InboxEventListener` contract on iOS and Android.
 *
 * @public
 */
export enum InboxEventType {
  /** A non-dismiss action (e.g. a button/link) was taken on an inbox message. */
  messageActionTaken = 'messageActionTaken',
  /** An inbox message was first shown/rendered in the visible inbox view. */
  messageShown = 'messageShown',
  /** An inbox message was marked opened (e.g. when the panel opens). */
  messageOpened = 'messageOpened',
  /** An inbox message was dismissed/removed from the inbox. */
  messageDismissed = 'messageDismissed',
}

/**
 * Event delivered to a registered inbox event listener.
 *
 * `messageActionTaken` carries `actionName`/`actionValue`; the observational
 * events (`messageShown`, `messageOpened`, `messageDismissed`) carry only the
 * message.
 *
 * @public
 */
export class InboxMessageEvent {
  /** The type of inbox event. */
  eventType: InboxEventType;
  /** The inbox message the event relates to. */
  message: InboxMessage;
  /** The Jist action name (only present for `messageActionTaken`). */
  actionName?: string;
  /** The resolved action value, typically a url (only present for `messageActionTaken`). */
  actionValue?: string;

  constructor(
    eventType: InboxEventType,
    message: InboxMessage,
    actionName?: string,
    actionValue?: string
  ) {
    this.eventType = eventType;
    this.message = message;
    this.actionName = actionName;
    this.actionValue = actionValue;
  }
}

/**
 * Host-provided accessibility labels for the Visual Notification Inbox UI.
 *
 * The SDK ships no text of its own in the visual inbox — the empty state is an icon and the
 * loading state is a spinner — so accessibility labels are the one place a string is still
 * needed. Because the SDK cannot know your app's language, every label is optional and unset by
 * default, and an omitted label leaves that element unlabeled rather than falling back to
 * English. Pass strings already localized for the user's language.
 *
 * @example
 * ```ts
 * CustomerIO.initialize({
 *   cdpApiKey: '...',
 *   inApp: {
 *     siteId: '...',
 *     notificationInboxAccessibilityLabels: {
 *       bell: t('inbox.bell'),
 *       bellWithUnreadCount: t('inbox.unread'), // e.g. "{count} unread notifications"
 *       loadingIndicator: t('inbox.loading'),
 *       emptyState: t('inbox.empty'),
 *     },
 *   },
 * });
 * ```
 *
 * @public
 */
export type NotificationInboxAccessibilityLabels = {
  /**
   * Label for the inbox bell button. Also used when the bell shows an unread badge but
   * `bellWithUnreadCount` is not provided. Unset → the bell is announced as an unnamed button
   * (it stays focusable and tappable; hiding it would leave screen reader users no way in).
   */
  bell?: string;
  /**
   * Label for the bell while it shows an unread badge. Include `{count}` where the number of
   * unread messages should appear; it is substituted at render time. Unset → falls back to `bell`.
   *
   * The badge itself is always hidden from assistive technologies, so the count is announced
   * only through this label, never as bare digits appended to the button.
   *
   * This is a template rather than a function because configuration crosses the native bridge,
   * which carries data but not callbacks. One template cannot express languages whose plural
   * rules need a distinct form per count.
   */
  bellWithUnreadCount?: string;
  /**
   * Label announced for the loading spinner. Unset → no label, leaving only the indeterminate
   * progress role that the platform describes in the device's own language.
   */
  loadingIndicator?: string;
  /** Label announced for the empty-state icon. Unset → the icon is treated as decorative. */
  emptyState?: string;
};
