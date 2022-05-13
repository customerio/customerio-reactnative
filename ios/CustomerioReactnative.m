#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(CustomerioReactnative, NSObject)

RCT_EXTERN_METHOD(initialize: (nonnull NSString *) siteId
                  apiKey : (nonnull NSString *) apiKey
                  region : (NSString *) region)

RCT_EXTERN_METHOD(identify: (nonnull NSString *) identifier
                  body : (NSDictionary *) body)

RCT_EXTERN_METHOD(clearIdentify)

@end
