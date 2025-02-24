import {
  CustomerIO,
  CioLogLevel,
  InAppMessageEventType,
  ScreenView,
} from 'customerio-reactnative';

const stringToScreenView = (str) => {
  if (str.toLowerCase() === ScreenView.InApp.toString().toLowerCase()) {
    return ScreenView.InApp;
  }
  return ScreenView.All;
};

export const initializeCustomerIoSDK = (sdkConfig) => {
  let screenViewUse = stringToScreenView(sdkConfig.screenViewUse);
  const config = {
    cdpApiKey: sdkConfig.cdpApiKey, // Mandatory
    migrationSiteId: sdkConfig.siteId, // For migration
    trackApplicationLifecycleEvents: sdkConfig.trackAppLifecycleEvents,
    autoTrackDeviceAttributes: sdkConfig.autoTrackDeviceAttributes,
    screenViewUse: screenViewUse,
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

  const message = `
  {
  "data": {
      "body": "Hope your are having a good day 🏖️",
      "image": "https://thumbs.dreamstime.com/b/bee-flower-27533578.jpg",
      "link": "amiapp-reactnative-apns://settings?site_id=sitid&api_key=apikey",
      "title": "Hello Rich 👋"
    }
  }    
  `
  CustomerIO.pushMessaging.onMessageReceived(message).then(handled => {
    // If true, the push was a Customer.io notification and handled by our SDK 
    // Otherwise, `handled` is false
    console.log('Push message handled: ', handled);
  });
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
