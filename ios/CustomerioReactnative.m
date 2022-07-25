#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(CustomerioReactnative, NSObject)

RCT_EXTERN_METHOD(initialize: (nonnull NSString *) siteId
                  apiKey : (nonnull NSString *) apiKey
                  region : (NSString *) region
                  configData : (NSDictionary *) configData)

RCT_EXTERN_METHOD(identify: (nonnull NSString *) identifier
                  body : (NSDictionary *) body)

RCT_EXTERN_METHOD(clearIdentify)

RCT_EXTERN_METHOD(track: (nonnull NSString *) name
                  data : (NSDictionary *) data)

RCT_EXTERN_METHOD(setDeviceAttributes : (nonnull NSDictionary *) data)

RCT_EXTERN_METHOD(setProfileAttributes : (nonnull NSDictionary *) data)

RCT_EXTERN_METHOD(screen: (nonnull NSString *) name
                  data : (NSDictionary *) data)

@end
