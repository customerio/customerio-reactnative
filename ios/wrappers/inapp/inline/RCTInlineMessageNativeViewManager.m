#ifndef RCT_NEW_ARCH_ENABLED

#import "ReactInlineMessageView.h"

#import <React/RCTUIManager.h>
#import <React/RCTViewManager.h>
#import <UIKit/UIKit.h>

/// Old architecture React Native view for inline messages
@interface RCTInlineMessageNativeView : UIView
/// Bridge to Swift ReactInlineMessageView for platform-agnostic implementation
@property(nonatomic, strong) id bridge;
@property(nonatomic, copy) NSString *elementId;
@property(nonatomic, copy) RCTDirectEventBlock onSizeChange;
@property(nonatomic, copy) RCTDirectEventBlock onStateChange;
@end

@implementation RCTInlineMessageNativeView

- (void)assertBridgeAvailable:(NSString *)context {
  NSAssert(self.bridge != nil, @"Bridge is nil when %@", context);
}

- (instancetype)init {
  if (self = [super init]) {
    // Create Swift bridge using runtime class resolution
    Class bridgeClass = NSClassFromString(@"ReactInlineMessageView");
    if (bridgeClass) {
      self.bridge = [[bridgeClass alloc] initWithContainerView:self];
      [self assertBridgeAvailable:@"creating ReactInlineMessageView bridge instance"];
      [self.bridge setEventEmitter:self];
    }
  }
  return self;
}

- (void)setElementId:(NSString *)elementId {
  _elementId = elementId;
  [self assertBridgeAvailable:@"setting elementId"];
  [self.bridge setElementId:elementId ?: @""];
}

- (void)setOnSizeChange:(RCTDirectEventBlock)onSizeChange {
  _onSizeChange = onSizeChange;
}

- (void)setOnStateChange:(RCTDirectEventBlock)onStateChange {
  _onStateChange = onStateChange;
}

// MARK: - Event Emitter Methods
- (void)emitOnSizeChangeEvent:(NSDictionary *)event {
  if (self.onSizeChange) {
    self.onSizeChange(event);
  }
}

- (void)emitOnStateChangeEvent:(NSDictionary *)event {
  if (self.onStateChange) {
    self.onStateChange(event);
  }
}

@end

/// React Native view manager for old architecture inline message views
@interface RCTInlineMessageNativeViewManager : RCTViewManager
@end

@implementation RCTInlineMessageNativeViewManager

RCT_EXPORT_MODULE(InlineMessageNative)

- (UIView *)view {
  return [[RCTInlineMessageNativeView alloc] init];
}

RCT_EXPORT_VIEW_PROPERTY(elementId, NSString)
RCT_EXPORT_VIEW_PROPERTY(onSizeChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onStateChange, RCTDirectEventBlock)

@end

#endif
