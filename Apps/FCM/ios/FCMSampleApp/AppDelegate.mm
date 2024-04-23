#import "AppDelegate.h"
#import <FCMSampleApp-Swift.h>
#import <React/RCTLinkingManager.h>
#import <React/RCTBundleURLProvider.h>
#import <FirebaseCore.h>

@implementation AppDelegate

// Create Object of class MyAppPushNotificationsHandler
MyAppPushNotificationsHandler *pnHandlerObj = [[MyAppPushNotificationsHandler alloc] init];

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.moduleName = @"FCMSampleApp";
  // You can add your custom initial props in the dictionary below.
  // They will be passed down to the ViewController used by React Native.
  self.initialProps = @{};

  // Configure Firebase
  [FIRApp configure];

  // Set FCM messaging delegate
  [FIRMessaging messaging].delegate = self;

  // Use modifiedLaunchOptions for passing link to React Native bridge to sends users to the specified screen
  NSMutableDictionary *modifiedLaunchOptions = [NSMutableDictionary dictionaryWithDictionary:launchOptions];
  if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
    NSDictionary *pushContent = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (pushContent[@"CIO"] && pushContent[@"CIO"][@"push"] && pushContent[@"CIO"][@"push"][@"link"]) {
      NSString *initialURL = pushContent[@"CIO"][@"push"][@"link"];
      if (!launchOptions[UIApplicationLaunchOptionsURLKey]) {
        modifiedLaunchOptions[UIApplicationLaunchOptionsURLKey] = [NSURL URLWithString:initialURL];
      }
    }
  }
  
  [pnHandlerObj setupCustomerIOClickHandling];

  return [super application:application didFinishLaunchingWithOptions:modifiedLaunchOptions];
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge {
  return [self getBundleURL];
}
 
- (NSURL *)getBundleURL {
  #if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

- (void)messaging:(FIRMessaging *)messaging didReceiveRegistrationToken:(NSString *)fcmToken {
  [pnHandlerObj didReceiveRegistrationToken:messaging fcmToken: fcmToken];
}

// Deep links handling for app scheme links
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
  return [RCTLinkingManager application:application openURL:url options:options];
}

// Deep links handling for universal links
- (BOOL)application:(UIApplication *)application
    continueUserActivity:(nonnull NSUserActivity *)userActivity
      restorationHandler:(nonnull void (^)(NSArray<id<UIUserActivityRestoring>> *_Nullable))restorationHandler {
  NSURL *url = userActivity.webpageURL;
  if (!url) {
    return NO;
  }

  // Universal link supported by the app
  NSURL *universalLinkUrl = [NSURL URLWithString:@"http://www.amiapp-reactnative-fcm.com"];

  // return true from this function if your app handled the deep link.
  // return false from this function if your app did not handle the deep link and you want sdk to open the URL in a browser.
  if (([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"]) && [url.host isEqualToString:universalLinkUrl.host]) {
    return [RCTLinkingManager application:application continueUserActivity:userActivity restorationHandler:restorationHandler];
  } else {
    return NO;
  }
}
@end
