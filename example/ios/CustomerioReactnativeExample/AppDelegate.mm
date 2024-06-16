#import "AppDelegate.h"

#import <React/RCTBundleURLProvider.h>
#import <CustomerioReactnativeExample-Swift.h>
#import <UserNotifications/UNUserNotificationCenter.h>


@implementation AppDelegate {
//  MyAppPushNotificationsHandler* pnHandlerObj = [[MyAppPushNotificationsHandler alloc] init];
  NSString *s;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.moduleName = @"CustomerioReactnativeExample";
  // You can add your custom initial props in the dictionary below.
  // They will be passed down to the ViewController used by React Native.
  self.initialProps = @{};
//  CustomerIO.initialize(withConfig: SDKConfigBuilder(cdpApiKey: "").build())
//  MessagingPushAPN.initialize(withConfig: MessagingPushConfigBuilder().build())
  [application registerForRemoteNotifications];
  [APNHandler setupCustomerIOClickHandling];

  [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert) completionHandler:^(BOOL granted, NSError * _Nullable error) {
      
  }];
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

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  [APNHandler application:application deviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  [APNHandler application:application error:error];
}

@end
