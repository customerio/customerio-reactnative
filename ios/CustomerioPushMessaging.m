#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(CustomerioPushMessaging, NSObject)

RCT_EXTERN_METHOD(trackNotificationResponseReceived : (nonnull NSDictionary *) payload])

RCT_EXTERN_METHOD(trackNotificationReceived : (nonnull NSDictionary *) payload])

@end
