import {
  CustomerIO,
  CioLogLevel,
  InAppMessageEventType,
} from 'customerio-reactnative';

export const initializeCustomerIoSDK = (sdkConfig) => {
  const config = {
    cdpApiKey: sdkConfig.cdpApiKey, // Mandatory
    migrationSiteId: sdkConfig.siteId, // For migration
    trackApplicationLifecycleEvents: sdkConfig.trackAppLifecycleEvents,
    autoTrackDeviceAttributes: sdkConfig.autoTrackDeviceAttributes,
    inApp: {
      siteId: sdkConfig.siteId,
    },
  };

  if (sdkConfig.debugMode) {
    config.logLevel = CioLogLevel.Debug;
  }
  CustomerIO.initialize(config);
};

export const onUserLoggedIn = (user) => {
  CustomerIO.identify({
    userId: user.email,
    traits: {
      first_name: user.name,
      email: user.email,
    },
  });
};

export const onUserLoggedOut = () => {
  CustomerIO.clearIdentify();
};

export const trackScreen = (screenName) => {
  CustomerIO.screen(screenName);
};

export const trackEvent = (eventName, propertyName, propertyValue) => {
  const data = {};
  if (propertyName) {
    data[propertyName] = propertyValue;
  }
  CustomerIO.track(eventName, data);
};

export const trackDeviceAttribute = (name, value) => {
  const data = {};
  data[name] = value;
  CustomerIO.setDeviceAttributes(data);
};

export const trackProfileAttribute = (name, value) => {
  const data = {};
  data[name] = value;
  CustomerIO.setProfileAttributes(data);
};

export const getPushPermissionStatus = async () => {
  return CustomerIO.pushMessaging.getPushPermissionStatus();
};

export const requestPushNotificationsPermission = (options) => {
  return CustomerIO.pushMessaging.showPromptForPushNotifications(options);
};

export const registerInAppEventListener = () => {
  const logInAppEvent = (name, params) => {
    console.log(`in-app message: ${name}, params: `, params);
  };

  const onInAppEventReceived = (eventName, eventParams) => {
    logInAppEvent(eventName, eventParams);

    const { deliveryId, messageId, actionValue, actionName } = eventParams;
    const data = {
      'event-name': eventName,
      'delivery-id': deliveryId ?? 'NULL',
      'message-id': messageId ?? 'NULL',
    };
    if (actionName) {
      data['action-name'] = actionName;
    }
    if (actionValue) {
      data['action-value'] = actionValue;
    }

    CustomerIO.track('in-app message action', data);
  };

  const inAppMessaging = CustomerIO.inAppMessaging;
  return inAppMessaging.registerEventsListener((event) => {
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
