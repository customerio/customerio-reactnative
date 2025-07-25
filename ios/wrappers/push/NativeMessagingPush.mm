#import "../utils/RCTCustomerIOUtils.h"
#import <React/RCTBridgeModule.h>

#ifdef RCT_NEW_ARCH_ENABLED

#import <RNCustomerIOSpec/RNCustomerIOSpec.h>

// Objective-C wrapper for new architecture TurboModule implementation
@interface RCTNativeMessagingPush : NSObject <NativeCustomerIOMessagingPushSpec>
// Bridge to Swift implementation for cross-language compatibility
@property(nonatomic, strong) id<NativeCustomerIOMessagingPushSpec> swiftBridge;
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
  }
  return self;
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

// Export class factory function for React Native component registration
Class<RCTBridgeModule> NativeCustomerIOMessagingPushCls(void) {
  return RCTNativeMessagingPush.class;
}

@end

#else

// Old Architecture: Bridge methods exposed via RCT_EXTERN macros
// Maps to Swift implementation without TurboModule overhead

@interface RCT_EXTERN_REMAP_MODULE (NativeCustomerIOMessagingPush, NativeMessagingPush, NSObject)

RCT_EXTERN_METHOD(trackNotificationResponseReceived : (NSDictionary *)payload)

RCT_EXTERN_METHOD(trackNotificationReceived : (NSDictionary *)payload)

RCT_EXTERN_METHOD(getRegisteredDeviceToken
                  : (RCTPromiseResolveBlock)resolve reject
                  : (RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(showPromptForPushNotifications
                  : (NSDictionary *)options resolve
                  : (RCTPromiseResolveBlock)resolve reject
                  : (RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getPushPermissionStatus
                  : (RCTPromiseResolveBlock)resolve reject
                  : (RCTPromiseRejectBlock)reject)

// Module initialization can happen on background thread
+ (BOOL)requiresMainQueueSetup {
  return NO;
}

@end

#endif
