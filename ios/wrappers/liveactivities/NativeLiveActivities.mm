#import <React/RCTBridgeModule.h>
#import <RNCustomerIOSpec/RNCustomerIOSpec.h>

// Objective-C wrapper for new architecture TurboModule implementation
@interface RCTNativeLiveActivities : NSObject <NativeCustomerIOLiveActivitiesSpec>
// Bridge to Swift implementation for cross-language compatibility
@property(nonatomic, strong) id<NativeCustomerIOLiveActivitiesSpec> swiftBridge;
@end

@implementation RCTNativeLiveActivities

RCT_EXPORT_MODULE()

// Create TurboModule instance for new architecture JSI integration
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeCustomerIOLiveActivitiesSpecJSI>(params);
}

- (instancetype)init {
  if (self = [super init]) {
    // Runtime class lookup - the Swift class only exists when the liveactivities subspec is installed.
    Class swiftClass = NSClassFromString(@"NativeCustomerIOLiveActivities");
    if (swiftClass) {
      _swiftBridge = [[swiftClass alloc] init];
    }
  }
  return self;
}

// Module initialization can happen on background thread
+ (BOOL)requiresMainQueueSetup {
  return NO;
}

- (void)start:(NSDictionary *)payload
      resolve:(RCTPromiseResolveBlock)resolve
       reject:(RCTPromiseRejectBlock)reject {
  if (!_swiftBridge) {
    reject(@"live_activity_module_unavailable", @"Live Activities are unavailable.", nil);
    return;
  }
  [_swiftBridge start:payload resolve:resolve reject:reject];
}

- (void)update:(NSString *)activityId
       payload:(NSDictionary *)payload
       resolve:(RCTPromiseResolveBlock)resolve
        reject:(RCTPromiseRejectBlock)reject {
  if (!_swiftBridge) {
    reject(@"live_activity_module_unavailable", @"Live Activities are unavailable.", nil);
    return;
  }
  [_swiftBridge update:activityId payload:payload resolve:resolve reject:reject];
}

- (void)end:(NSString *)activityId
    payload:(NSDictionary *)payload
    resolve:(RCTPromiseResolveBlock)resolve
     reject:(RCTPromiseRejectBlock)reject {
  if (!_swiftBridge) {
    reject(@"live_activity_module_unavailable", @"Live Activities are unavailable.", nil);
    return;
  }
  [_swiftBridge end:activityId payload:payload resolve:resolve reject:reject];
}

- (void)startCustom:(NSString *)activityType
            payload:(NSDictionary *)payload
            resolve:(RCTPromiseResolveBlock)resolve
             reject:(RCTPromiseRejectBlock)reject {
  if (!_swiftBridge) {
    reject(@"live_activity_module_unavailable", @"Live Activities are unavailable.", nil);
    return;
  }
  [_swiftBridge startCustom:activityType payload:payload resolve:resolve reject:reject];
}

// Export class factory function for React Native component registration
Class<RCTBridgeModule> NativeCustomerIOLiveActivitiesCls(void) {
  return RCTNativeLiveActivities.class;
}

@end
