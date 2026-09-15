import type { CioConfig } from 'customerio-reactnative';

// The SDK ships no text of its own in the visual notification inbox, so these labels are the only
// strings it can announce. A real app would resolve them through its own i18n so they follow the
// user's language; they are hardcoded here only to keep the sample self-contained.
const INBOX_ACCESSIBILITY_LABELS = {
  bell: 'Notifications',
  bellWithUnreadCount: 'Notifications, {count} unread',
  loadingIndicator: 'Loading inbox',
  emptyState: 'No notifications',
};

/**
 * Adds the inbox accessibility labels to a config on its way to `CustomerIO.initialize`.
 *
 * Applied at the initialize call sites rather than stored with the Settings config, which is both
 * persisted and user-editable: the labels are not something a tester should be able to edit away,
 * and keeping them out of storage means Settings needs no special handling to preserve them.
 *
 * Every path that initializes the SDK has to go through here. Native `initialize` ignores every
 * call after the first, so a path that skips these labels and happens to run first leaves the
 * inbox unlabeled for the rest of the process.
 */
export const withInboxAccessibilityLabels = (config: CioConfig): CioConfig =>
  config.inApp
    ? {
        ...config,
        inApp: {
          ...config.inApp,
          notificationInboxAccessibilityLabels: INBOX_ACCESSIBILITY_LABELS,
        },
      }
    : config;
