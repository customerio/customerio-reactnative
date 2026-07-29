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
   * Called when the user taps the bell.
   *
   * Observational only — the SDK opens the inbox itself, so there is nothing the
   * host has to do in response. Reports any tap inside this view's frame, which
   * is the bell when the view is sized to it as recommended.
   */
  onTap?: () => void;
}

/**
 * The Visual Notification Inbox bell (with unread badge). Tapping it opens the
 * SDK's own inbox panel — the host presents nothing.
 *
 * Place it wherever the app's layout calls for it. Remote branding still styles
 * the bell itself (colors, icon), but branding's *position* is not applied: the
 * host owns placement via `style`. The bell renders nothing when the inbox has
 * nothing to show, so give it a fixed size for predictable layout — at least 88
 * points/dp square, since the native composition insets the 56pt bell by 16 on
 * each side and a smaller box squeezes the circle onto the glyph.
 *
 * @example
 * ```tsx
 * <NotificationInboxBellView
 *   style={{ width: 88, height: 88 }}
 *   onTap={() => analytics.track('inbox_bell_tapped')}
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
