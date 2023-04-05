
#import "NotificationService.h"
#import "Notification_Service-Swift.h"

@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    NotificationServiceCioManager* cioManagerObj = [[NotificationServiceCioManager alloc] init];
    [cioManagerObj didReceive:request withContentHandler:contentHandler];
}

- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    NotificationServiceCioManager* cioManagerObj = [[NotificationServiceCioManager alloc] init];
    [cioManagerObj serviceExtensionTimeWillExpire];
}

@end
