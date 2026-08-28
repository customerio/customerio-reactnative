#import "utils/RCTCustomerIOUtils.h"
#import <React/RCTBridgeModule.h>
#import <React/RCTInvalidating.h>
#import <RNCustomerIOSpec/RNCustomerIOSpec.h>

@protocol NativeCustomerIOBridge <NativeCustomerIOSpec, RCTInvalidating>
- (void)setEventEmitter:(id)emitter;
@end

// Objective-C wrapper for new architecture TurboModule implementation
@interface RCTNativeCustomerIO : NativeCustomerIOSpecBase <NativeCustomerIOSpec>
// Bridge to Swift implementation for cross-language compatibility
@property(nonatomic, strong) id<NativeCustomerIOBridge> swiftBridge;
@end

@implementation RCTNativeCustomerIO

RCT_EXPORT_MODULE()

// Create TurboModule instance for new architecture JSI integration
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeCustomerIOSpecJSI>(params);
}

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
    [_swiftBridge setEventEmitter:self];
  }
  return self;
}

// Module initialization can happen on background thread
+ (BOOL)requiresMainQueueSetup {
  return NO;
}

- (void)initialize:(NSDictionary *)config
              args:(NSDictionary *)args
           resolve:(RCTPromiseResolveBlock)resolve
            reject:(RCTPromiseRejectBlock)reject {
  [self assertBridgeAvailable:@"during initialize"];
  [_swiftBridge initialize:config args:args resolve:resolve reject:reject];
}

- (void)setDeepLinkRoutingReady {
  [self assertBridgeAvailable:@"during setDeepLinkRoutingReady"];
  [_swiftBridge setDeepLinkRoutingReady];
}

- (void)registerDeepLinkHandler {
  [self assertBridgeAvailable:@"during registerDeepLinkHandler"];
  [_swiftBridge registerDeepLinkHandler];
}

- (void)unregisterDeepLinkHandler {
  [self assertBridgeAvailable:@"during unregisterDeepLinkHandler"];
  [_swiftBridge unregisterDeepLinkHandler];
}

- (void)acknowledgeDeepLink:(NSString *)id handled:(BOOL)handled {
  [self assertBridgeAvailable:@"during acknowledgeDeepLink"];
  [_swiftBridge acknowledgeDeepLink:id handled:handled];
}

- (void)invalidate {
  [self assertBridgeAvailable:@"during invalidate"];
  [_swiftBridge invalidate];
}

// Pins the Codegen event name at compile time. Keep this in sync with the TypeScript spec and the
// runtime selector in NativeCustomerIO.swift.
- (void)emitOnDeepLinkReceived:(NSDictionary *)value {
  [super emitOnDeepLinkReceived:value];
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

- (void)trackMetric:(NSString *)deliveryID
        deviceToken:(NSString *)deviceToken
              event:(NSString *)event {
  [self assertBridgeAvailable:@"during trackMetric"];
  [_swiftBridge trackMetric:deliveryID deviceToken:deviceToken event:event];
}

- (void)deleteDeviceToken {
  [self assertBridgeAvailable:@"during deleteDeviceToken"];
  [_swiftBridge deleteDeviceToken];
}

// Export class factory function for React Native component registration
Class<RCTBridgeModule> NativeCustomerIOCls(void) { return RCTNativeCustomerIO.class; }

@end
