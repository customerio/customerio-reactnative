// See RCTInlineMessageNative.h for why this RCTViewComponentView import is guarded by __cplusplus:
// the header transitively includes Fabric C++ that must only be parsed in Objective-C++ (.mm) mode.
#ifdef __cplusplus
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCTNotificationInboxOverlayNative : RCTViewComponentView
@end

NS_ASSUME_NONNULL_END
#endif
