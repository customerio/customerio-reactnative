/**
 * Android-specific behavior when a push notification is clicked.
 *
 * Controls how the Android system handles activity lifecycle
 * when users tap on push notifications.
 *
 * @public
 */
export enum PushClickBehaviorAndroid {
  /** Clear the activity task stack and start fresh */
  ResetTaskStack = 'RESET_TASK_STACK',
  /** Prevent the current activity from restarting */
  ActivityPreventRestart = 'ACTIVITY_PREVENT_RESTART',
  /** Use default behavior without special flags */
  ActivityNoFlags = 'ACTIVITY_NO_FLAGS',
}

/**
 * Push notification permission request options.
 *
 * Configure which types of notifications to request permission for
 * on different platforms.
 *
 * @public
 */
export type CioPushPermissionOptions = {
  ios?: {
    /** Request permission to show badge numbers on app icon */
    badge: boolean;
    /** Request permission to play notification sounds */
    sound: boolean;
  };
};

/**
 * Current push notification permission status.
 *
 * Indicates whether the user has granted, denied, or not yet
 * responded to push notification permission requests.
 *
 * @public
 */
export enum CioPushPermissionStatus {
  /** User has granted push notification permissions */
  Granted = 'GRANTED',
  /** User has denied push notification permissions */
  Denied = 'DENIED',
  /** User may not yet have been asked for permissions and permission status is unknown */
  NotDetermined = 'NOTDETERMINED',
}
