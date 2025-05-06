//
//  RCTPushMessagingTurboModule.mm
//  customerio-reactnative
//
//  Created for CustomerIO React Native SDK
//

#import "RCTPushMessagingTurboModule.h"
#import <CioInternalCommon/CioInternalCommon.h>
#import <CioMessagingPush/CioMessagingPush.h>
#import <React/RCTUtils.h>
#import <UserNotifications/UserNotifications.h>

// Constants for permission status
static NSString *const PermissionStatusGranted = @"GRANTED";
static NSString *const PermissionStatusDenied = @"DENIED";
static NSString *const PermissionStatusNotDetermined = @"NOTDETERMINED";

@interface RCTPushMessagingTurboModule ()
@property(nonatomic, strong) CioInternalCommon.Logger *logger;
@end

@implementation RCTPushMessagingTurboModule

RCT_EXPORT_MODULE(PushMessagingModule)

- (id)init {
  if (self = [super init]) {
    _logger = DIGraphShared.shared.logger;
  }
  return self;
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::PushMessagingModuleSpecJSI>(params);
}

#pragma mark - PushMessagingModuleSpec Methods

- (void)handleMessage:(NSDictionary *)message
    handleNotificationTrigger:(BOOL)handleNotificationTrigger
                     resolver:(RCTPromiseResolveBlock)resolve
                     rejecter:(RCTPromiseRejectBlock)reject {
  // iOS doesn't need to handle this as push notifications work fine with
  // multiple notification services Resolving promise to true makes it easier
  // for callers to avoid adding unnecessary platform specific checks
  resolve(@YES);
}

- (void)trackNotificationResponseReceived:(NSDictionary *)payload {
  if (payload) {
    [MessagingPush.shared trackNotificationResponseReceived:payload];
  }
}

- (void)trackNotificationReceived:(NSDictionary *)payload {
  if (payload) {
    [MessagingPush.shared trackNotificationReceived:payload];
  }
}

- (void)getRegisteredDeviceToken:(RCTPromiseResolveBlock)resolve
                        rejecter:(RCTPromiseRejectBlock)reject {
  NSString *token = [MessagingPush.shared getRegisteredDeviceToken];
  if (token) {
    resolve(token);
  } else {
    reject(@"no_token", @"No device token is registered", nil);
  }
}

- (void)showPromptForPushNotifications:(NSDictionary *)options
                              resolver:(RCTPromiseResolveBlock)resolve
                              rejecter:(RCTPromiseRejectBlock)reject {
  UNAuthorizationOptions authOptions = UNAuthorizationOptionAlert;

  if (options && [options isKindOfClass:[NSDictionary class]]) {
    NSDictionary *iosOptions = options[@"ios"];
    if (iosOptions && [iosOptions isKindOfClass:[NSDictionary class]]) {
      if ([iosOptions[@"badge"] boolValue]) {
        authOptions |= UNAuthorizationOptionBadge;
      }
      if ([iosOptions[@"sound"] boolValue]) {
        authOptions |= UNAuthorizationOptionSound;
      }
    }
  }

  [UNUserNotificationCenter.currentNotificationCenter
      requestAuthorizationWithOptions:authOptions
                    completionHandler:^(BOOL granted,
                                        NSError *_Nullable error) {
                      dispatch_async(dispatch_get_main_queue(), ^{
                        if (error) {
                          reject(@"permission_error",
                                 error.localizedDescription, error);
                        } else {
                          resolve(granted ? PermissionStatusGranted
                                          : PermissionStatusDenied);
                        }
                      });
                    }];
}

- (void)getPushPermissionStatus:(RCTPromiseResolveBlock)resolve
                       rejecter:(RCTPromiseRejectBlock)reject {
  [UNUserNotificationCenter.currentNotificationCenter
      getNotificationSettingsWithCompletionHandler:^(
          UNNotificationSettings *_Nonnull settings) {
        dispatch_async(dispatch_get_main_queue(), ^{
          switch (settings.authorizationStatus) {
          case UNAuthorizationStatusAuthorized:
          case UNAuthorizationStatusProvisional:
          case UNAuthorizationStatusEphemeral:
            resolve(PermissionStatusGranted);
            break;
          case UNAuthorizationStatusDenied:
            resolve(PermissionStatusDenied);
            break;
          case UNAuthorizationStatusNotDetermined:
          default:
            resolve(PermissionStatusNotDetermined);
            break;
          }
        });
      }];
}

- (NSDictionary *)PermissionStatus {
  return @{
    @"Granted" : PermissionStatusGranted,
    @"Denied" : PermissionStatusDenied,
    @"NotDetermined" : PermissionStatusNotDetermined
  };
}

- (NSDictionary *)PushClickBehavior {
  // This is Android-specific, but we provide empty values for iOS for
  // consistency
  return @{
    @"ResetTaskStack" : @"RESET_TASK_STACK",
    @"ActivityPreventRestart" : @"ACTIVITY_PREVENT_RESTART",
    @"ActivityNoFlags" : @"ACTIVITY_NO_FLAGS"
  };
}

@end