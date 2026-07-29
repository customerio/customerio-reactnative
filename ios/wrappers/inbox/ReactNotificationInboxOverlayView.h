#import <Foundation/Foundation.h>

@class UIView;

NS_ASSUME_NONNULL_BEGIN

/**
 * Objective-C forward declaration for the Swift `ReactNotificationInboxOverlayView` class.
 *
 * Mirrors `ReactInlineMessageView.h`: provides method declarations for compile-time safety while
 * the Swift bridge is resolved at runtime via `NSClassFromString`, avoiding Swift module-header
 * issues in mixed static/dynamic linking configurations.
 */
@interface ReactNotificationInboxOverlayView : NSObject

- (instancetype)initWithContainerView:(UIView *)containerView;
- (void)updateLayout:(NSValue *)boundsValue;
- (void)prepareForRecycle;

@end

NS_ASSUME_NONNULL_END
