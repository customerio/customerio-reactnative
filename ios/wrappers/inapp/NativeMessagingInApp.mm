#import "../utils/RCTCustomerIOUtils.h"
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <React/RCTInitializing.h>
#import <React/RCTInvalidating.h>
#import <RNCustomerIOSpec/RNCustomerIOSpec.h>

// Protocol that extends the spec with setEventEmitter method
@protocol NativeMessagingInAppBridge <NativeCustomerIOMessagingInAppSpec, RCTInitializing, RCTInvalidating>
- (void)setEventEmitter:(id)emitter;
@end

// Objective-C wrapper for new architecture TurboModule implementation
@interface RCTNativeMessagingInApp
    : NativeCustomerIOMessagingInAppSpecBase <NativeCustomerIOMessagingInAppSpec>
// Bridge to Swift implementation for cross-language compatibility
@property(nonatomic, strong) id<NativeMessagingInAppBridge> swiftBridge;
@end

@implementation RCTNativeMessagingInApp

RCT_EXPORT_MODULE()

// Create TurboModule instance for new architecture JSI integration
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeCustomerIOMessagingInAppSpecJSI>(params);
}

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

- (void)setupInboxListener {
  [self assertBridgeAvailable:@"during setupInboxListener"];
  [_swiftBridge setupInboxListener];
}

- (void)getMessages:(NSString *)topic
            resolve:(RCTPromiseResolveBlock)resolve
             reject:(RCTPromiseRejectBlock)reject {
  [self assertBridgeAvailable:@"during getMessages"];
  [_swiftBridge getMessages:topic resolve:resolve reject:reject];
}

- (void)markMessageOpened:(NSDictionary *)message {
  [self assertBridgeAvailable:@"during markMessageOpened"];
  [_swiftBridge markMessageOpened:message];
}

- (void)markMessageUnopened:(NSDictionary *)message {
  [self assertBridgeAvailable:@"during markMessageUnopened"];
  [_swiftBridge markMessageUnopened:message];
}

- (void)markMessageDeleted:(NSDictionary *)message {
  [self assertBridgeAvailable:@"during markMessageDeleted"];
  [_swiftBridge markMessageDeleted:message];
}

- (void)trackMessageClicked:(NSDictionary *)message actionName:(NSString *)actionName {
  [self assertBridgeAvailable:@"during trackMessageClicked"];
  [_swiftBridge trackMessageClicked:message actionName:actionName];
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

- (void)emitSubscribeToMessagesChanged:(NSDictionary *)value {
  [super emitSubscribeToMessagesChanged:value];
}

// Export class factory function for React Native component registration
Class<RCTBridgeModule> NativeCustomerIOMessagingInAppCls(void) {
  return RCTNativeMessagingInApp.class;
}

@end
