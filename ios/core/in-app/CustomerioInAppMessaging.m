#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(CustomerioInAppMessaging, RCTEventEmitter)

RCT_EXTERN_METHOD(supportedEvents)

RCT_EXTERN_METHOD(dismissMessage)

@end
