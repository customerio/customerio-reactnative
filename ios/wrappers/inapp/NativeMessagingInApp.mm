#import "../utils/RCTCustomerIOUtils.h"
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

#ifdef RCT_NEW_ARCH_ENABLED

#import <RNCustomerIOSpec/RNCustomerIOSpec.h>

// Protocol that extends the spec with setEventEmitter method
@protocol NativeMessagingInAppBridge <NativeCustomerIOMessagingInAppSpec>
- (void)setEventEmitter:(id)emitter;
- (void)initialize;
- (void)invalidate;
@end

// Objective-C wrapper for new architecture TurboModule implementation
@interface RCTNativeMessagingInApp
    : NativeCustomerIOMessagingInAppSpecBase <NativeCustomerIOMessagingInAppSpec>
// Bridge to Swift implementation for cross-language compatibility
@property(nonatomic, strong) id<NativeMessagingInAppBridge> swiftBridge;
@end

@implementation RCTNativeMessagingInApp

RCT_EXPORT_MODULE()

#ifdef RCT_NEW_ARCH_ENABLED
// Create TurboModule instance for new architecture JSI integration
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeCustomerIOMessagingInAppSpecJSI>(params);
}
#endif

// Validates Swift bridge is available before method calls
- (void)assertBridgeAvailable:(NSString *)context {
  RCT_ASSERT_BRIDGE_AVAILABLE(self.swiftBridge, context);
}

- (instancetype)init {
  if (self = [super init]) {
    // Use runtime class lookup to avoid import issues and circular dependencies
    Class swiftClass = NSClassFromString(@"NativeMessagingInApp");
    RCT_ASSERT_NOT_NIL(swiftClass, @"NativeMessagingInApp Swift class", @"during runtime lookup");
    _swiftBridge = [[swiftClass alloc] init];
    [self assertBridgeAvailable:@"creating NativeMessagingInApp Swift instance"];

    // Set event emitter reference for new architecture
    [_swiftBridge setEventEmitter:self];
  }
  return self;
}

// Module initialization can happen on background thread
+ (BOOL)requiresMainQueueSetup {
  return NO;
}

- (void)initialize {
  [self assertBridgeAvailable:@"during initialize"];
  [_swiftBridge initialize];
}

- (void)invalidate {
  [self assertBridgeAvailable:@"during invalidate"];
  [_swiftBridge invalidate];
}

- (void)dismissMessage {
  [self assertBridgeAvailable:@"during dismissMessage"];
  [_swiftBridge dismissMessage];
}

- (void)addListener:(nonnull NSString *)eventName {
  RCT_LEGACY_ARCH_WARNING(addListener);
}

- (void)removeListeners:(double)count {
  RCT_LEGACY_ARCH_WARNING(removeListeners);
}

- (void)emitOnInAppEventReceived:(NSDictionary *)value {
  [super emitOnInAppEventReceived:value];
}

// Export class factory function for React Native component registration
Class<RCTBridgeModule> NativeCustomerIOMessagingInAppCls(void) {
  return RCTNativeMessagingInApp.class;
}

@end

#else

// Old Architecture: Bridge methods exposed via RCT_EXTERN macros
// Maps to Swift implementation without TurboModule overhead

@interface RCT_EXTERN_REMAP_MODULE (NativeCustomerIOMessagingInApp, NativeMessagingInApp,
                                    RCTEventEmitter)

RCT_EXTERN_METHOD(supportedEvents)
RCT_EXTERN_METHOD(dismissMessage)

// Module initialization can happen on background thread
+ (BOOL)requiresMainQueueSetup {
  return NO;
}

@end

#endif
