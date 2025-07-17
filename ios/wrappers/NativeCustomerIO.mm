#import "utils/RCTCustomerIOUtils.h"
#import <React/RCTBridgeModule.h>

#ifdef RCT_NEW_ARCH_ENABLED

#import <RNCustomerIOSpec/RNCustomerIOSpec.h>

// Objective-C wrapper for new architecture TurboModule implementation
@interface RCTNativeCustomerIO : NSObject <NativeCustomerIOSpec>
// Bridge to Swift implementation for cross-language compatibility
@property(nonatomic, strong) id<NativeCustomerIOSpec> swiftBridge;
@end

@implementation RCTNativeCustomerIO

RCT_EXPORT_MODULE()

#ifdef RCT_NEW_ARCH_ENABLED
// Create TurboModule instance for new architecture JSI integration
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeCustomerIOSpecJSI>(params);
}
#endif

// Validates Swift bridge is available before method calls
- (void)assertBridgeAvailable:(NSString *)context {
  RCT_ASSERT_BRIDGE_AVAILABLE(self.swiftBridge, context);
}

- (instancetype)init {
  if (self = [super init]) {
    // Use runtime class lookup to avoid import issues and circular dependencies
    Class swiftClass = NSClassFromString(@"NativeCustomerIO");
    RCT_ASSERT_NOT_NIL(swiftClass, @"NativeCustomerIO Swift class", @"during runtime lookup");
    _swiftBridge = [[swiftClass alloc] init];
    [self assertBridgeAvailable:@"creating NativeCustomerIO Swift instance"];
  }
  return self;
}

// Module initialization can happen on background thread
+ (BOOL)requiresMainQueueSetup {
  return NO;
}

- (void)initialize:(NSDictionary *)config args:(NSDictionary *)args {
  [self assertBridgeAvailable:@"during initialize"];
  [_swiftBridge initialize:config args:args];
}

- (void)identify:(NSDictionary *)params {
  [self assertBridgeAvailable:@"during identify"];
  [_swiftBridge identify:params];
}

- (void)clearIdentify {
  [self assertBridgeAvailable:@"during clearIdentify"];
  [_swiftBridge clearIdentify];
}

- (void)track:(NSString *)name properties:(NSDictionary *)properties {
  [self assertBridgeAvailable:@"during track"];
  [_swiftBridge track:name properties:properties];
}

- (void)screen:(NSString *)title properties:(NSDictionary *)properties {
  [self assertBridgeAvailable:@"during screen"];
  [_swiftBridge screen:title properties:properties];
}

- (void)setProfileAttributes:(NSDictionary *)attributes {
  [self assertBridgeAvailable:@"during setProfileAttributes"];
  [_swiftBridge setProfileAttributes:attributes];
}

- (void)setDeviceAttributes:(NSDictionary *)attributes {
  [self assertBridgeAvailable:@"during setDeviceAttributes"];
  [_swiftBridge setDeviceAttributes:attributes];
}

- (void)registerDeviceToken:(NSString *)token {
  [self assertBridgeAvailable:@"during registerDeviceToken"];
  [_swiftBridge registerDeviceToken:token];
}

- (void)deleteDeviceToken {
  [self assertBridgeAvailable:@"during deleteDeviceToken"];
  [_swiftBridge deleteDeviceToken];
}

// Export class factory function for React Native component registration
Class<RCTBridgeModule> NativeCustomerIOCls(void) { return RCTNativeCustomerIO.class; }

@end

#else

// Old Architecture: Bridge methods exposed via RCT_EXTERN macros
// Maps to Swift implementation without TurboModule overhead

@interface RCT_EXTERN_REMAP_MODULE (NativeCustomerIO, NativeCustomerIO, NSObject)

RCT_EXTERN_METHOD(initialize : (NSDictionary *)config args : (NSDictionary *)args)
RCT_EXTERN_METHOD(identify : (NSDictionary *)params)
RCT_EXTERN_METHOD(clearIdentify)
RCT_EXTERN_METHOD(track : (NSString *)name properties : (NSDictionary *)properties)
RCT_EXTERN_METHOD(screen : (NSString *)title properties : (NSDictionary *)properties)
RCT_EXTERN_METHOD(setProfileAttributes : (NSDictionary *)attributes)
RCT_EXTERN_METHOD(setDeviceAttributes : (NSDictionary *)attributes)
RCT_EXTERN_METHOD(registerDeviceToken : (NSString *)token)
RCT_EXTERN_METHOD(deleteDeviceToken)

// Module initialization can happen on background thread
+ (BOOL)requiresMainQueueSetup {
  return NO;
}

@end

#endif
