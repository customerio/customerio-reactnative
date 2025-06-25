#ifndef RCT_NEW_ARCH_ENABLED

#import "customerio_reactnative-Swift.h"

#import <React/RCTUIManager.h>
#import <React/RCTViewManager.h>

/// Old architecture React Native view for inline messages
@interface RCTInlineMessageNativeView : UIView <ReactInlineMessageEventEmitterProtocol>
/// Bridge to Swift ReactInlineMessageView for platform-agnostic implementation
@property(nonatomic, strong) id<ReactInlineMessageViewProtocol> bridge;
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
    // Create Swift bridge using runtime class resolution due to Swift-ObjC interop limitations
    Class bridgeClass = NSClassFromString(@"ReactInlineMessageView");
    NSAssert(bridgeClass != nil, @"ReactInlineMessageView class not found - check Swift bridging header");

    if (bridgeClass) {
      SEL initSelector = NSSelectorFromString(@"initWithContainerView:");
      NSAssert([bridgeClass instancesRespondToSelector:initSelector],
               @"ReactInlineMessageView does not respond to initWithContainerView:");

      if ([bridgeClass instancesRespondToSelector:initSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        self.bridge = [[bridgeClass alloc] performSelector:initSelector withObject:self];
#pragma clang diagnostic pop
        // Set up event emitter for old architecture only if bridge was created successfully
        [self assertBridgeAvailable:@"creating ReactInlineMessageView bridge instance"];
        [self.bridge setEventEmitter:self];
      }
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

// MARK: - ReactInlineMessageEventEmitterProtocol
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
