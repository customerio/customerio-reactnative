#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(CustomerioReactnative, NSObject)

RCT_EXTERN_METHOD(initialize: (nonnull NSDictionary *) env
                  configData : (NSDictionary *) configData
                  packageConfig: (nonnull NSDictionary *) packageConfig)

RCT_EXTERN_METHOD(identify: (nonnull NSString *) identifier
                  body : (NSDictionary *) body)

RCT_EXTERN_METHOD(clearIdentify)

RCT_EXTERN_METHOD(track: (nonnull NSString *) name
                  data : (NSDictionary *) data)

RCT_EXTERN_METHOD(setDeviceAttributes : (nonnull NSDictionary *) data)

RCT_EXTERN_METHOD(setProfileAttributes : (nonnull NSDictionary *) data)

RCT_EXTERN_METHOD(screen: (nonnull NSString *) name
                  data : (NSDictionary *) data)

RCT_EXTERN_METHOD(registerDeviceToken : (nonnull NSString *) token)

RCT_EXTERN_METHOD(deleteDeviceToken)

RCT_EXTERN_METHOD(showPromptForPushNotifications: (NSDictionary *) options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getPushPermissionStatus: (RCTPromiseResolveBlock) resolver
                  rejecter:(RCTPromiseRejectBlock)rejecter)

RCT_EXTERN_METHOD(trackNotificationResponseReceived : (nonnull NSDictionary *) payload])

RCT_EXTERN_METHOD(trackNotificationReceived : (nonnull NSDictionary *) payload])

@end
