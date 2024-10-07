#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_REMAP_MODULE(CioRctInAppMessaging, CioRctInAppMessaging, RCTEventEmitter)

RCT_EXTERN_METHOD(supportedEvents)

RCT_EXTERN_METHOD(dismissMessage)

@end
