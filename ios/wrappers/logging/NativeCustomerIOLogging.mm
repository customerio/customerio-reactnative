#import "../utils/RCTCustomerIOUtils.h"
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTInitializing.h>
#import <React/RCTInvalidating.h>

#ifdef RCT_NEW_ARCH_ENABLED

#import <RNCustomerIOSpec/RNCustomerIOSpec.h>

// Protocol that extends the spec with event emitter methods
@protocol NativeCustomerIOLoggingBridge <NativeCustomerIOLoggingSpec, RCTInitializing, RCTInvalidating>
- (void)setEventEmitter:(id)emitter;
@end

// Objective-C wrapper for new architecture TurboModule implementation
@interface RCTNativeCustomerIOLogging
    : NativeCustomerIOLoggingSpecBase <NativeCustomerIOLoggingSpec>
// Bridge to Swift implementation for cross-language compatibility
@property(nonatomic, strong) id<NativeCustomerIOLoggingBridge> swiftBridge;
@end

@implementation RCTNativeCustomerIOLogging

RCT_EXPORT_MODULE()

#ifdef RCT_NEW_ARCH_ENABLED
// Create TurboModule instance for new architecture JSI integration
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeCustomerIOLoggingSpecJSI>(params);
}
#endif

// Validates Swift bridge is available before method calls
- (void)assertBridgeAvailable:(NSString *)context {
  RCT_ASSERT_BRIDGE_AVAILABLE(self.swiftBridge, context);
}

- (instancetype)init {
  if (self = [super init]) {
    // Use runtime class lookup to avoid import issues and circular dependencies
    Class swiftClass = NSClassFromString(@"NativeCustomerIOLogging");
    RCT_ASSERT_NOT_NIL(swiftClass, @"NativeCustomerIOLogging Swift class", @"during runtime lookup");
    _swiftBridge = [[swiftClass alloc] init];
    [self assertBridgeAvailable:@"creating NativeCustomerIOLogging Swift instance"];

    // Set event emitter reference for new architecture
    [_swiftBridge setEventEmitter:self];
  }
  return self;
}

// Background initialization is fine since logs are ignored until listeners are attached
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

- (void)isNewArchEnabled:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  resolve(@(YES));
}

- (void)addListener:(nonnull NSString *)eventName {
  RCT_LEGACY_ARCH_WARNING(addListener);
}

- (void)removeListeners:(double)count {
  RCT_LEGACY_ARCH_WARNING(removeListeners);
}

- (void)emitOnCioLogEvent:(NSDictionary *)value {
  [super emitOnCioLogEvent:value];
}

// Export class factory function for React Native component registration
Class<RCTBridgeModule> NativeCustomerIOLoggingCls(void) {
  return RCTNativeCustomerIOLogging.class;
}

@end

#else

// Old Architecture: Bridge methods exposed via RCT_EXTERN macros
// Maps to Swift implementation without TurboModule overhead

@interface RCT_EXTERN_REMAP_MODULE (NativeCustomerIOLogging, NativeCustomerIOLoggingLegacy,
                                    RCTEventEmitter)

RCT_EXTERN_METHOD(supportedEvents)

RCT_REMAP_METHOD(isNewArchEnabled, isNewArchEnabledWithResolver
                 : (RCTPromiseResolveBlock)resolve rejecter
                 : (RCTPromiseRejectBlock)reject) {
  resolve(@(NO));
}

// Background initialization is fine since logs are ignored until listeners are attached
+ (BOOL)requiresMainQueueSetup {
  return NO;
}

@end

#endif
