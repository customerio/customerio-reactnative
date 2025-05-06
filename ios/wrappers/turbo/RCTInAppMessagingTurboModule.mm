//
//  RCTInAppMessagingTurboModule.mm
//  customerio-reactnative
//
//  Created for CustomerIO React Native SDK
//

#import "RCTInAppMessagingTurboModule.h"
#import <CioInternalCommon/CioInternalCommon.h>
#import <CioMessagingInApp/CioMessagingInApp.h>
#import <React/RCTEventEmitter.h>

// Constants for event names
static NSString *const InAppEventListenerEventName = @"InAppEventListener";
static NSString *const MessageShownEvent = @"messageShown";
static NSString *const MessageDismissedEvent = @"messageDismissed";
static NSString *const MessageActionTakenEvent = @"messageActionTaken";
static NSString *const ErrorWithMessageEvent = @"errorWithMessage";

// Constants for event data keys
static NSString *const EventTypeKey = @"eventType";
static NSString *const MessageIdKey = @"messageId";
static NSString *const DeliveryIdKey = @"deliveryId";
static NSString *const ActionValueKey = @"actionValue";
static NSString *const ActionNameKey = @"actionName";

@interface RCTInAppMessagingTurboModule ()
@property(nonatomic, strong) RCTEventEmitter *eventEmitter;
@property(nonatomic, strong) CioInternalCommon.Logger *logger;
@end

@implementation RCTInAppMessagingTurboModule

RCT_EXPORT_MODULE(InAppMessagingModule)

- (id)init {
  if (self = [super init]) {
    _logger = DIGraphShared.shared.logger;
    _eventEmitter = [[RCTEventEmitter alloc] init];
  }
  return self;
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::InAppMessagingModuleSpecJSI>(params);
}

#pragma mark - InAppMessagingModuleSpec Methods

- (void)dismissMessage {
  [MessagingInApp.shared dismissMessage];
}

- (NSString *)InAppEventListenerEventName {
  return InAppEventListenerEventName;
}

- (NSDictionary *)Events {
  return @{
    @"MessageShown" : MessageShownEvent,
    @"MessageDismissed" : MessageDismissedEvent,
    @"MessageActionTaken" : MessageActionTakenEvent,
    @"ErrorWithMessage" : ErrorWithMessageEvent
  };
}

#pragma mark - InAppEventListener Methods

- (void)messageShown:(InAppMessage *)message {
  [self sendEventWithType:MessageShownEvent message:message];
}

- (void)messageDismissed:(InAppMessage *)message {
  [self sendEventWithType:MessageDismissedEvent message:message];
}

- (void)errorWithMessage:(InAppMessage *)message {
  [self sendEventWithType:ErrorWithMessageEvent message:message];
}

- (void)messageActionTaken:(InAppMessage *)message
               actionValue:(NSString *)actionValue
                actionName:(NSString *)actionName {
  [self sendEventWithType:MessageActionTakenEvent
                  message:message
              actionValue:actionValue
               actionName:actionName];
}

#pragma mark - Helper Methods

- (void)sendEventWithType:(NSString *)eventType
                  message:(InAppMessage *)message {
  [self sendEventWithType:eventType
                  message:message
              actionValue:nil
               actionName:nil];
}

- (void)sendEventWithType:(NSString *)eventType
                  message:(InAppMessage *)message
              actionValue:(NSString *)actionValue
               actionName:(NSString *)actionName {
  NSMutableDictionary *body = [NSMutableDictionary dictionaryWithDictionary:@{
    EventTypeKey : eventType,
    MessageIdKey : message.messageId,
    DeliveryIdKey : message.deliveryId ?: [NSNull null]
  }];

  if (actionValue) {
    body[ActionValueKey] = actionValue;
  }

  if (actionName) {
    body[ActionNameKey] = actionName;
  }

  [self.eventEmitter sendEventWithName:InAppEventListenerEventName body:body];
}

@end