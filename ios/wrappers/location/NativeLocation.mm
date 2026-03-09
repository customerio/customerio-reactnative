#import "../utils/RCTCustomerIOUtils.h"
#import <React/RCTBridgeModule.h>
#import <RNCustomerIOSpec/RNCustomerIOSpec.h>

// Objective-C wrapper for new architecture TurboModule implementation
@interface RCTNativeCustomerIOLocation : NSObject <NativeCustomerIOLocationSpec>
// Bridge to Swift implementation for cross-language compatibility
@property(nonatomic, strong) id<NativeCustomerIOLocationSpec> swiftBridge;
@end

@implementation RCTNativeCustomerIOLocation

RCT_EXPORT_MODULE()

// Create TurboModule instance for new architecture JSI integration
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeCustomerIOLocationSpecJSI>(params);
}

// Validates Swift bridge is available before method calls
- (void)assertBridgeAvailable:(NSString *)context {
  RCT_ASSERT_BRIDGE_AVAILABLE(self.swiftBridge, context);
}

- (instancetype)init {
  if (self = [super init]) {
    // Use runtime class lookup to avoid import issues and circular dependencies
    Class swiftClass = NSClassFromString(@"NativeLocation");
    RCT_ASSERT_NOT_NIL(swiftClass, @"NativeLocation Swift class", @"during runtime lookup");
    _swiftBridge = [[swiftClass alloc] init];
    [self assertBridgeAvailable:@"creating NativeLocation Swift instance"];
  }
  return self;
}

// Module initialization can happen on background thread
+ (BOOL)requiresMainQueueSetup {
  return NO;
}

- (void)setLastKnownLocation:(double)latitude
                    longitude:(double)longitude {
  [self assertBridgeAvailable:@"during setLastKnownLocation"];
  [_swiftBridge setLastKnownLocation:latitude longitude:longitude];
}

- (void)requestLocationUpdate {
  [self assertBridgeAvailable:@"during requestLocationUpdate"];
  [_swiftBridge requestLocationUpdate];
}

// Export class factory function for React Native component registration
Class<RCTBridgeModule> NativeCustomerIOLocationCls(void) {
  return RCTNativeCustomerIOLocation.class;
}

@end
