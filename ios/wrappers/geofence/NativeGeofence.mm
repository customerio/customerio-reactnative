#import <React/RCTBridgeModule.h>
#import <RNCustomerIOSpec/RNCustomerIOSpec.h>

// Objective-C wrapper for new architecture TurboModule implementation
@interface RCTNativeCustomerIOGeofence : NSObject <NativeCustomerIOGeofenceSpec>
// Bridge to Swift implementation for cross-language compatibility
@property(nonatomic, strong) id<NativeCustomerIOGeofenceSpec> swiftBridge;
@end

@implementation RCTNativeCustomerIOGeofence

RCT_EXPORT_MODULE()

// Create TurboModule instance for new architecture JSI integration
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeCustomerIOGeofenceSpecJSI>(params);
}

- (instancetype)init {
  if (self = [super init]) {
    // Use runtime class lookup - NativeGeofence class only exists when the CioLocationGeofence subspec is installed
    Class swiftClass = NSClassFromString(@"NativeCustomerIOGeofence");
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

- (void)refreshFromCurrentLocation {
  if (!_swiftBridge) return;
  [_swiftBridge refreshFromCurrentLocation];
}

// Export class factory function for React Native component registration
Class<RCTBridgeModule> NativeCustomerIOGeofenceCls(void) {
  return RCTNativeCustomerIOGeofence.class;
}

@end
