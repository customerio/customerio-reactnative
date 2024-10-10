import {
  CioLogLevel,
  CustomerIO,
  CioPushPermissionOptions,
  InAppMessageEvent,
  InAppMessageEventType,
} from 'customerio-reactnative';
import User from '../data/models/user';
import CustomerIoSDKConfig from '../data/sdk/CustomerIoSDKConfig';

export const initializeCustomerIoSDK = (sdkConfig: CustomerIoSDKConfig) => {
  const config = {
    cdpApiKey: sdkConfig.cdpApiKey, // Mandatory
    migrationSiteId: sdkConfig.siteId, // For migration
    trackApplicationLifecycleEvents: sdkConfig.trackAppLifecycleEvents,
    autoTrackDeviceAttributes: sdkConfig.trackDeviceAttributes,
    inApp: {
      siteId: sdkConfig.siteId,
    },
    logLevel: CioLogLevel.None, // Add logLevel property
  };
  if (sdkConfig.debugMode) {
    config.logLevel = CioLogLevel.Debug;
  }
  CustomerIO.initialize(config)
};

export const onUserLoggedIn = (user: User) => {
  CustomerIO.identify({
    userId: user.email,
    traits: {
      first_name: user.name,
      email: user.email,
    }
  });
};

export const onUserLoggedOut = () => {
  CustomerIO.clearIdentify();
};

export const trackScreen = (screenName: string) => {
  CustomerIO.screen(screenName);
};

export const trackEvent = (
  eventName: string,
  propertyName?: string,
  propertyValue?: any,
) => {
  const data = propertyName ? { [propertyName]: propertyValue } : {};
  CustomerIO.track(eventName, data);
};

export const trackDeviceAttribute = (name: string, value: any) => {
  const data = { [name]: value };
  CustomerIO.setDeviceAttributes(data);
};

export const trackProfileAttribute = (name: string, value: any) => {
  const data = { [name]: value };
  CustomerIO.setProfileAttributes(data);
};

export const getPushPermissionStatus = () => {
  return CustomerIO.pushMessaging.getPushPermissionStatus();
};

export const requestPushNotificationsPermission = (
  options: typeof CioPushPermissionOptions,
) => {
  return CustomerIO.pushMessaging.showPromptForPushNotifications(options);
};


export const registerInAppEventListener = () => {
  const logInAppEvent = (name: string, params: InAppMessageEvent) => {
    console.log(`in-app message: ${name}, params: `, params);
  };

  const onInAppEventReceived = (
    eventName: string,
    eventParams: InAppMessageEvent,
  ) => {
    logInAppEvent(eventName, eventParams);

    const { deliveryId, messageId, actionValue, actionName } = eventParams;
    const data: Map<string, any> = new Map();
    data.set('event-name', eventName);
    data.set('delivery-id', deliveryId ?? 'NULL');
    data.set('message-id', messageId ?? 'NULL');
    if (actionName) {
      data.set('action-name', actionName);
    }
    if (actionValue) {
      data.set('action-value', actionValue);
    }

    CustomerIO.track('in-app message action', data);
  };

  const inAppMessaging = CustomerIO.inAppMessaging;
  return inAppMessaging.registerEventsListener((event: InAppMessageEvent) => {
    switch (event.eventType) {
      case InAppMessageEventType.messageShown:
        onInAppEventReceived('messageShown', event);
        break;

      case InAppMessageEventType.messageDismissed:
        onInAppEventReceived('messageDismissed', event);
        break;

      case InAppMessageEventType.errorWithMessage:
        onInAppEventReceived('errorWithMessage', event);
        break;

      case InAppMessageEventType.messageActionTaken:
        onInAppEventReceived('messageActionTaken', event);
        // Dismiss in app message if the action is 'dismiss' or 'close'
        if (event.actionValue === 'dismiss' || event.actionValue === 'close') {
          inAppMessaging.dismissMessage();
        }
        break;

      default:
        onInAppEventReceived('unsupported event', event);
    }
  });
};
