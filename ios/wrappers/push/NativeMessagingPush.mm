#import "../utils/RCTCustomerIOUtils.h"
#import <React/RCTBridgeModule.h>
#import <React/RCTInvalidating.h>
#import <RNCustomerIOSpec/RNCustomerIOSpec.h>

@protocol NativeMessagingPushBridge <NativeCustomerIOMessagingPushSpec, RCTInvalidating>
- (void)setEventEmitter:(id)emitter;
@end

// Runs at process start, before iOS can deliver a silent push that launched the app. A constructor
// because RCT_EXPORT_MODULE already defines +load.
__attribute__((constructor)) static void RCTNativeMessagingPushInstallBackgroundPushHandler(void) {
  Class swiftClass = NSClassFromString(@"NativeMessagingPush");
  SEL selector = NSSelectorFromString(@"installWrapperBackgroundPushHandler");
  if ([swiftClass respondsToSelector:selector]) {
    ((void (*)(id, SEL))[swiftClass methodForSelector:selector])(swiftClass, selector);
  }
}

// Objective-C wrapper for new architecture TurboModule implementation
@interface RCTNativeMessagingPush
    : NativeCustomerIOMessagingPushSpecBase <NativeCustomerIOMessagingPushSpec>
// Bridge to Swift implementation for cross-language compatibility
@property(nonatomic, strong) id<NativeMessagingPushBridge> swiftBridge;
@end

@implementation RCTNativeMessagingPush

RCT_EXPORT_MODULE()

// Create TurboModule instance for new architecture JSI integration
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeCustomerIOMessagingPushSpecJSI>(params);
}

// Validates Swift bridge is available before method calls
- (void)assertBridgeAvailable:(NSString *)context {
  RCT_ASSERT_BRIDGE_AVAILABLE(self.swiftBridge, context);
}

- (instancetype)init {
  if (self = [super init]) {
    // Use runtime class lookup to avoid import issues and circular dependencies
    Class swiftClass = NSClassFromString(@"NativeMessagingPush");
    RCT_ASSERT_NOT_NIL(swiftClass, @"NativeMessagingPush Swift class", @"during runtime lookup");
    _swiftBridge = [[swiftClass alloc] init];
    [self assertBridgeAvailable:@"creating NativeMessagingPush Swift instance"];
    [_swiftBridge setEventEmitter:self];
  }
  return self;
}

- (void)invalidate {
  [self assertBridgeAvailable:@"during invalidate"];
  [_swiftBridge invalidate];
}

// Module initialization can happen on background thread
+ (BOOL)requiresMainQueueSetup {
  return NO;
}

- (void)onMessageReceived:(NSDictionary *)message
    handleNotificationTrigger:(BOOL)handleNotificationTrigger
                      resolve:(RCTPromiseResolveBlock)resolve
                       reject:(RCTPromiseRejectBlock)reject {
  [self assertBridgeAvailable:@"during handleMessage"];
  [_swiftBridge onMessageReceived:message
        handleNotificationTrigger:handleNotificationTrigger
                          resolve:resolve
                           reject:reject];
}

- (void)trackNotificationResponseReceived:(NSDictionary *)payload {
  [self assertBridgeAvailable:@"during trackNotificationResponseReceived"];
  [_swiftBridge trackNotificationResponseReceived:payload];
}

- (void)trackNotificationReceived:(NSDictionary *)payload {
  [self assertBridgeAvailable:@"during trackNotificationReceived"];
  [_swiftBridge trackNotificationReceived:payload];
}

- (void)getRegisteredDeviceToken:(RCTPromiseResolveBlock)resolve
                          reject:(RCTPromiseRejectBlock)reject {
  [self assertBridgeAvailable:@"during getRegisteredDeviceToken"];
  [_swiftBridge getRegisteredDeviceToken:resolve reject:reject];
}

- (void)showPromptForPushNotifications:(NSDictionary *)options
                               resolve:(RCTPromiseResolveBlock)resolve
                                reject:(RCTPromiseRejectBlock)reject {
  [self assertBridgeAvailable:@"during showPromptForPushNotifications"];
  [_swiftBridge showPromptForPushNotifications:options resolve:resolve reject:reject];
}

- (void)getPushPermissionStatus:(RCTPromiseResolveBlock)resolve
                         reject:(RCTPromiseRejectBlock)reject {
  [self assertBridgeAvailable:@"during getPushPermissionStatus"];
  [_swiftBridge getPushPermissionStatus:resolve reject:reject];
}

- (void)registerBackgroundPushHandler {
  [self assertBridgeAvailable:@"during registerBackgroundPushHandler"];
  [_swiftBridge registerBackgroundPushHandler];
}

- (void)unregisterBackgroundPushHandler {
  [self assertBridgeAvailable:@"during unregisterBackgroundPushHandler"];
  [_swiftBridge unregisterBackgroundPushHandler];
}

- (void)acknowledgeBackgroundPush:(NSString *)id {
  [self assertBridgeAvailable:@"during acknowledgeBackgroundPush"];
  [_swiftBridge acknowledgeBackgroundPush:id];
}

- (void)emitOnBackgroundPushReceived:(NSDictionary *)value {
  [super emitOnBackgroundPushReceived:value];
}

// Export class factory function for React Native component registration
Class<RCTBridgeModule> NativeCustomerIOMessagingPushCls(void) {
  return RCTNativeMessagingPush.class;
}

@end
