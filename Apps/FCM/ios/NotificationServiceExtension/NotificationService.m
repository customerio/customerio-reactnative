#import <NotificationServiceExtension-Swift.h>
#import "NotificationService.h"

@interface NotificationService ()

@property(nonatomic, strong) void (^contentHandler)(UNNotificationContent* contentToDeliver);
@property(nonatomic, strong) UNMutableNotificationContent* bestAttemptContent;

@end

@implementation NotificationService

// Create object of class MyAppNotificationServicePushHandler
MyAppNotificationServicePushHandler* nsHandlerObj = nil;

// Initialize the object
+ (void)initialize {
  nsHandlerObj = [[MyAppNotificationServicePushHandler alloc] init];
}

- (void)didReceiveNotificationRequest:(UNNotificationRequest*)request withContentHandler:(void (^)(UNNotificationContent* _Nonnull))contentHandler {
  [nsHandlerObj didReceive:request withContentHandler:contentHandler];
}

- (void)serviceExtensionTimeWillExpire {
  [nsHandlerObj serviceExtensionTimeWillExpire];
}

@end
