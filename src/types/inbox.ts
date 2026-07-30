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
