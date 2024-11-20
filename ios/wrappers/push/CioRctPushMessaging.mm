#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_REMAP_MODULE (CioRctPushMessaging, CioRctPushMessaging, NSObject)

RCT_EXTERN_METHOD(trackNotificationResponseReceived : (NSDictionary*)payload)

RCT_EXTERN_METHOD(trackNotificationReceived : (NSDictionary*)payload)

RCT_EXTERN_METHOD(getRegisteredDeviceToken
                  : (RCTPromiseResolveBlock)resolver rejecter
                  : (RCTPromiseRejectBlock)rejecter)

RCT_EXTERN_METHOD(showPromptForPushNotifications
                  : (NSDictionary*)options resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getPushPermissionStatus
                  : (RCTPromiseResolveBlock)resolver rejecter
                  : (RCTPromiseRejectBlock)reject)

@end
