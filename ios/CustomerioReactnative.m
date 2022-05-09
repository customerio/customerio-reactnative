#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(CustomerioReactnative, NSObject)

RCT_EXTERN_METHOD(multiply:(float)a withB:(float)b
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(initialize: (nonnull NSString *) siteId
                  apiKey : (nonnull NSString *) apiKey
                  region : (NSString *) region)

@end
