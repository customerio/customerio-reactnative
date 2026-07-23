#import <React/RCTBridgeModule.h>

// Bridges the Swift `SampleCustomLiveActivity` sample module to React Native. Promise-returning
// methods for driving the app-owned custom "rideshare" Live Activity from JS.
@interface RCT_EXTERN_MODULE (SampleCustomLiveActivity, NSObject)

RCT_EXTERN_METHOD(startRideshare
                  : (NSString *)driverName status
                  : (NSString *)status eta
                  : (nonnull NSNumber *)eta resolve
                  : (RCTPromiseResolveBlock)resolve reject
                  : (RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(updateRideshare
                  : (NSString *)activityId status
                  : (NSString *)status eta
                  : (nonnull NSNumber *)eta resolve
                  : (RCTPromiseResolveBlock)resolve reject
                  : (RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(endRideshare
                  : (NSString *)activityId resolve
                  : (RCTPromiseResolveBlock)resolve reject
                  : (RCTPromiseRejectBlock)reject)

@end
