#import "RCTNotificationInboxBellNative.h"
#import "ReactNotificationInboxBellView.h"

#import <React/RCTConversions.h>
#import <React/RCTFabricComponentsPlugins.h>
#import <react/renderer/components/RNCustomerIOSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNCustomerIOSpec/EventEmitters.h>
#import <react/renderer/components/RNCustomerIOSpec/Props.h>
#import <react/renderer/components/RNCustomerIOSpec/RCTComponentViewHelpers.h>
#import <react/renderer/components/RNCustomerIOSpec/ShadowNodes.h>

using namespace facebook::react;

/// New-architecture React Native view hosting the SwiftUI NotificationInboxBell.
@interface RCTNotificationInboxBellNative () <RCTNotificationInboxBellNativeViewProtocol>
@property(nonatomic, strong) id bridge;
@end

@implementation RCTNotificationInboxBellNative

- (void)assertBridgeAvailable:(NSString *)context {
  NSAssert(self.bridge != nil, @"Bridge is nil when %@", context);
}

- (instancetype)init {
  return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    _props = NotificationInboxBellNativeShadowNode::defaultSharedProps();

    // The Swift bridge is @available(iOS 16.0, *) because the bell opens the SDK's inbox sheet, which
    // uses system detents. Below iOS 16 the class exists but must not be instantiated, so the view
    // stays empty rather than crashing — every method below therefore tolerates a nil bridge.
    if (@available(iOS 16.0, *)) {
      Class bridgeClass = NSClassFromString(@"ReactNotificationInboxBellView");
      if (bridgeClass) {
        self.bridge = [[bridgeClass alloc] initWithContainerView:self];
        [self assertBridgeAvailable:@"creating ReactNotificationInboxBellView bridge instance"];
        [self.bridge setEventEmitter:self];
      }
    }
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  if (self.bridge == nil) {
    return;
  }
  [self.bridge updateLayout:[NSValue valueWithCGRect:self.bounds]];
}

// Containment can only happen once the view is in a window: React Native creates component views
// before mounting them, so at init there is no parent view controller to attach the host to.
- (void)didMoveToWindow {
  [super didMoveToWindow];
  if (self.bridge == nil) {
    return;
  }
  if (self.window != nil) {
    [self.bridge attachToParentViewController];
  } else {
    [self.bridge detachFromParentViewController];
  }
}

- (void)prepareForRecycle {
  [super prepareForRecycle];
  if (self.bridge == nil) {
    return;
  }
  [self.bridge prepareForRecycle];
}

- (void)emitOnTapEvent:(NSDictionary *)event {
  if (_eventEmitter) {
    NotificationInboxBellNativeEventEmitter::OnTap result =
        NotificationInboxBellNativeEventEmitter::OnTap{};
    self.eventEmitter.onTap(result);
  }
}

- (const NotificationInboxBellNativeEventEmitter &)eventEmitter {
  return static_cast<const NotificationInboxBellNativeEventEmitter &>(*_eventEmitter);
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<NotificationInboxBellNativeComponentDescriptor>();
}

@end

Class<RCTComponentViewProtocol> NotificationInboxBellNativeCls(void) {
  return RCTNotificationInboxBellNative.class;
}
