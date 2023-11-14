#import <RCTAppDelegate.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import <FirebaseMessaging/FIRMessaging.h>

@interface AppDelegate : RCTAppDelegate <UNUserNotificationCenterDelegate, FIRMessagingDelegate>

@end
