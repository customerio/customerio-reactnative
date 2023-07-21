
#import "NotificationService.h"
#import "NotificationServiceExtension-Swift.h"

@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation NotificationService

// Create object of class NotificationServicePushHandler
NotificationServicePushHandler* nsHandlerObj = nil;

// Initialize the object
+ (void)initialize{
  nsHandlerObj = [[NotificationServicePushHandler alloc] init];
}

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
  [nsHandlerObj didReceive:request withContentHandler:contentHandler];
}

- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
  [nsHandlerObj serviceExtensionTimeWillExpire];
}

@end
