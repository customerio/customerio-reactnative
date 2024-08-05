#import "AppDelegate.h"

#import <React/RCTBundleURLProvider.h>
#import <UserNotifications/UNUserNotificationCenter.h>
#import <CustomerIOReactNativePush-Swift.h>
#import "Constants.h"
#import <React/RCTLinkingManager.h>

#if __has_include(<FirebaseMessaging/FirebaseMessaging.h>)
#define FCM
#import <FirebaseMessaging/FirebaseMessaging.h>
#else
#define APN
#endif

#ifdef FCM
@interface AppDelegate(FCM)<FIRMessagingDelegate>
@end
#endif

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.moduleName = MODULE_NAME;
  // You can add your custom initial props in the dictionary below.
  // They will be passed down to the ViewController used by React Native.
  self.initialProps = @{
    @"moduleName": MODULE_NAME
  };
  
  // 1. Setup CioMessagingPush
  [CioMessagingPush setup];
  
  // 2. Request user permissions for push
  [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert) completionHandler:^(BOOL granted, NSError * _Nullable error) {
  
  }];
  
  // 3. Register for remote notification
  [application registerForRemoteNotifications];
  
  // 4. For FCM, set its delgate
#ifdef FCM
  [FIRMessaging messaging].delegate = self;
#endif

  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
  return [self bundleURL];
}

- (NSURL *)bundleURL
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

// Deep linking
 - (BOOL)application:(UIApplication *)application
   openURL:(NSURL *)url
   options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
 {
   return [RCTLinkingManager application:application openURL:url options:options];
 }
@end
