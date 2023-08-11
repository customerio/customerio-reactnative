#import <UIKit/UIKit.h>
#import <RCTAppDelegate.h>
#import <React/RCTLinkingManager.h>
#import <React/RCTBundleURLProvider.h>
#import <UserNotifications/UserNotifications.h>
#import <FirebaseCore.h>
#import <FirebaseMessaging/FIRMessaging.h>
#import <FCMSampleApp-Swift.h>

@interface AppDelegate : RCTAppDelegate <UNUserNotificationCenterDelegate, FIRMessagingDelegate>

@end
