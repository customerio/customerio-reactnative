#import <Foundation/Foundation.h>

@class UIView;

NS_ASSUME_NONNULL_BEGIN

/**
 * Objective-C header for Swift ReactInlineMessageView class.
 *
 * This header provides a forward declaration for Swift interop without requiring
 * Swift module headers, which can cause compilation issues in mixed static/dynamic
 * linking configurations (e.g., FCM vs APN push providers).
 *
 * The actual Swift implementation is in ReactInlineMessageView.swift.
 * This header provides method declarations for compile-time safety while using
 * runtime class resolution (NSClassFromString) for the Swift bridge.
 */

/// Forward declaration of ReactInlineMessageView Swift class
@interface ReactInlineMessageView : NSObject

/// Initializes the view with a container view
- (instancetype)initWithContainerView:(UIView *)containerView;

/// Sets the event emitter for React Native communication
- (void)setEventEmitter:(id)eventEmitter;

/// Sets the element ID for the inline message
- (void)setElementId:(NSString *)elementId;

/// Prepares the view for reuse in React Native lifecycle
- (void)setupForReuse;

/// Updates the view layout with new bounds
- (void)updateLayout:(NSValue *)boundsValue;

/// Prepares the view for recycling
- (void)prepareForRecycle;

@end

NS_ASSUME_NONNULL_END
