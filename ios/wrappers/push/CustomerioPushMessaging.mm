#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_REMAP_MODULE(CustomerioPushMessaging, CustomerioPushMessaging, NSObject)

RCT_EXTERN_METHOD(trackNotificationResponseReceived : (nonnull NSDictionary *) payload])

RCT_EXTERN_METHOD(trackNotificationReceived : (nonnull NSDictionary *) payload])

RCT_EXTERN_METHOD(getRegisteredDeviceToken: (RCTPromiseResolveBlock) resolver
                  rejecter:(RCTPromiseRejectBlock)rejecter)

RCT_EXTERN_METHOD(showPromptForPushNotifications: (NSDictionary *) options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

@end
