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

- (instancetype)init {
  if (self = [super init]) {
    // Use runtime class lookup - NativeLocation class only exists when CioLocation subspec is installed
    Class swiftClass = NSClassFromString(@"NativeCustomerIOLocation");
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

- (void)setLastKnownLocation:(double)latitude
                    longitude:(double)longitude {
  if (!_swiftBridge) return;
  [_swiftBridge setLastKnownLocation:latitude longitude:longitude];
}

- (void)requestLocationUpdate {
  if (!_swiftBridge) return;
  [_swiftBridge requestLocationUpdate];
}

// Export class factory function for React Native component registration
Class<RCTBridgeModule> NativeCustomerIOLocationCls(void) {
  return RCTNativeCustomerIOLocation.class;
}

@end
