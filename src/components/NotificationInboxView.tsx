import React from 'react';
import NotificationInboxViewNativeComponent, {
  type NativeProps,
} from '../specs/components/NotificationInboxViewNativeComponent';

/**
 * Props for the {@link NotificationInboxView} component.
 */
/** @public */
export interface NotificationInboxViewProps extends NativeProps {}

/**
 * The Visual Notification Inbox message list — the Jist-rendered messages —
 * embeddable directly in your own screen. It fills the area you give it via
 * `style` and brings no surrounding chrome (no bell, no scrim).
 *
 * Message actions are handled by the existing global InboxEventListener, so this
 * component takes no per-message action callback.
 *
 * @example
 * ```tsx
 * <NotificationInboxView style={{ flex: 1 }} />
 * ```
 */
/** @public */
const NotificationInboxView: React.FC<NotificationInboxViewProps> = (props) => {
  return <NotificationInboxViewNativeComponent {...props} />;
};

export default NotificationInboxView;
