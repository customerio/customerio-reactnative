import React from 'react';
import { StyleSheet } from 'react-native';
import NotificationInboxOverlayNativeComponent, {
  type NativeProps,
} from '../specs/components/NotificationInboxOverlayNativeComponent';

/**
 * Props for the {@link NotificationInboxOverlayView} component.
 */
/** @public */
export interface NotificationInboxOverlayViewProps extends NativeProps {}

/**
 * Drop-in Visual Notification Inbox overlay: a floating bell pinned to the
 * corner that slides out the Jist-rendered message list. Mount it once near the
 * top of your screen so it overlays the rest of your content.
 *
 * Message actions are handled by the existing global InboxEventListener, so this
 * component takes no per-message action callback. Panel open/close is owned by the
 * native overlay and is not surfaced to JS.
 *
 * On iOS this requires iOS 16+ (the native overlay presents a sheet with system
 * detents); on earlier versions it renders nothing. The bell and list components
 * have no such floor.
 *
 * @example
 * ```tsx
 * <NotificationInboxOverlayView style={StyleSheet.absoluteFill} />
 * ```
 */
/** @public */
const NotificationInboxOverlayView: React.FC<
  NotificationInboxOverlayViewProps
> = ({ style, ...props }) => {
  return (
    <NotificationInboxOverlayNativeComponent
      {...props}
      style={[styles.fill, style]}
    />
  );
};

const styles = StyleSheet.create({
  // The overlay manages its own floating placement; default to filling the parent.
  fill: {
    ...StyleSheet.absoluteFillObject,
  },
});

export default NotificationInboxOverlayView;
