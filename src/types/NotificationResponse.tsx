export interface NotificationResponse {
    notification: Notification;
    actionIdentifier: string;
    userText?: string;
  }

  export interface Notification {
    date: number;
    request: NotificationRequest;
  }

  export interface NotificationRequest {
    identifier: string;
    content: NotificationContent;
  }

  export type NotificationContent = {
    title: string | null;
    subtitle: string | null;
    body: string | null;
    data: { [key: string]: unknown };
    sound: 'default' | 'defaultCritical' | 'custom' | null;
  } & (
    | {
        launchImageName: string | null;
        badge: number | null;
        attachments: {
          identifier: string | null;
          url: string | null;
          type: string | null;
        }[];
        summaryArgument?: string | null;
        summaryArgumentCount?: number;
        categoryIdentifier: string | null;
        threadIdentifier: string | null;
        targetContentIdentifier?: string;
      }
    | {
        badge?: number;
        /**
         * Format: '#AARRGGBB'
         */
        color?: string;
        vibrationPattern?: number[];
      }
  );