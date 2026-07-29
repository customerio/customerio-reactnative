#import <Foundation/Foundation.h>

@class UIView;

NS_ASSUME_NONNULL_BEGIN

/**
 * Objective-C forward declaration for the Swift `ReactNotificationInboxView` class.
 * See `ReactNotificationInboxOverlayView.h` for the rationale behind runtime resolution.
 */
@interface ReactNotificationInboxView : NSObject

- (instancetype)initWithContainerView:(UIView *)containerView;
- (void)setEventEmitter:(id)eventEmitter;
- (void)updateLayout:(NSValue *)boundsValue;
- (void)prepareForRecycle;

@end

NS_ASSUME_NONNULL_END
