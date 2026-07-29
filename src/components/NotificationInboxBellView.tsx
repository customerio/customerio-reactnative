import React from 'react';
import NotificationInboxBellNativeComponent, {
  type NativeProps,
} from '../specs/components/NotificationInboxBellNativeComponent';

/**
 * Props for the {@link NotificationInboxBellView} component.
 */
/** @public */
export interface NotificationInboxBellViewProps extends Omit<
  NativeProps,
  'onTap'
> {
  /**
   * Called when the user taps the bell. The host is responsible for presenting
   * its own inbox UI (e.g. navigate to a screen embedding
   * {@link NotificationInboxView}).
   */
  onTap?: () => void;
}

/**
 * Just the Visual Notification Inbox bell (with unread badge). The host opens
 * its own UI in response to {@link NotificationInboxBellViewProps.onTap}.
 *
 * The bell renders nothing when the inbox has nothing to show, so give it a
 * fixed size via `style` for predictable layout.
 *
 * @example
 * ```tsx
 * <NotificationInboxBellView
 *   style={{ width: 56, height: 56 }}
 *   onTap={() => navigation.navigate('Inbox')}
 * />
 * ```
 */
/** @public */
const NotificationInboxBellView: React.FC<NotificationInboxBellViewProps> = ({
  onTap,
  ...props
}) => {
  const handleTap = () => {
    onTap?.();
  };

  return <NotificationInboxBellNativeComponent {...props} onTap={handleTap} />;
};

export default NotificationInboxBellView;
