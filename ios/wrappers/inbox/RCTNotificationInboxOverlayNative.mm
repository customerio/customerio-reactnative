#import "RCTNotificationInboxOverlayNative.h"
#import "ReactNotificationInboxOverlayView.h"

#import <React/RCTConversions.h>
#import <React/RCTFabricComponentsPlugins.h>
#import <react/renderer/components/RNCustomerIOSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNCustomerIOSpec/EventEmitters.h>
#import <react/renderer/components/RNCustomerIOSpec/Props.h>
#import <react/renderer/components/RNCustomerIOSpec/RCTComponentViewHelpers.h>
#import <react/renderer/components/RNCustomerIOSpec/ShadowNodes.h>

using namespace facebook::react;

/// New-architecture React Native view hosting the SwiftUI NotificationInboxOverlay.
/// Mirrors RCTInlineMessageNative: bridges to the Swift view via runtime class resolution.
@interface RCTNotificationInboxOverlayNative () <RCTNotificationInboxOverlayNativeViewProtocol>
@property(nonatomic, strong) id bridge;
@end

@implementation RCTNotificationInboxOverlayNative

- (void)assertBridgeAvailable:(NSString *)context {
  NSAssert(self.bridge != nil, @"Bridge is nil when %@", context);
}

- (instancetype)init {
  return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    _props = NotificationInboxOverlayNativeShadowNode::defaultSharedProps();

    // The Swift bridge is @available(iOS 16.0, *) because the native overlay presents its panel in a
    // sheet with system detents. On earlier versions the class exists but must not be instantiated,
    // so the view stays empty rather than crashing.
    if (@available(iOS 16.0, *)) {
      Class bridgeClass = NSClassFromString(@"ReactNotificationInboxOverlayView");
      if (bridgeClass) {
        self.bridge = [[bridgeClass alloc] initWithContainerView:self];
        [self assertBridgeAvailable:@"creating ReactNotificationInboxOverlayView bridge instance"];
      }
    }
  }
  return self;
}

// The bridge is deliberately absent below iOS 16 (see initWithFrame), so these tolerate a nil bridge
// instead of asserting — an unsupported OS renders an empty view rather than crashing.
- (void)layoutSubviews {
  [super layoutSubviews];
  if (self.bridge == nil) {
    return;
  }
  [self.bridge updateLayout:[NSValue valueWithCGRect:self.bounds]];
}

- (void)prepareForRecycle {
  [super prepareForRecycle];
  if (self.bridge == nil) {
    return;
  }
  [self.bridge prepareForRecycle];
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<NotificationInboxOverlayNativeComponentDescriptor>();
}

@end

Class<RCTComponentViewProtocol> NotificationInboxOverlayNativeCls(void) {
  return RCTNotificationInboxOverlayNative.class;
}
