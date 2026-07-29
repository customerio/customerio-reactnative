#import "RCTNotificationInboxViewNative.h"
#import "ReactNotificationInboxView.h"

#import <React/RCTConversions.h>
#import <React/RCTFabricComponentsPlugins.h>
#import <react/renderer/components/RNCustomerIOSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNCustomerIOSpec/EventEmitters.h>
#import <react/renderer/components/RNCustomerIOSpec/Props.h>
#import <react/renderer/components/RNCustomerIOSpec/RCTComponentViewHelpers.h>
#import <react/renderer/components/RNCustomerIOSpec/ShadowNodes.h>

using namespace facebook::react;

/// New-architecture React Native view hosting the SwiftUI NotificationInboxView (message list).
/// This view emits no events; message actions flow through the existing global InboxEventListener.
@interface RCTNotificationInboxViewNative () <RCTNotificationInboxViewNativeViewProtocol>
@property(nonatomic, strong) id bridge;
@end

@implementation RCTNotificationInboxViewNative

- (void)assertBridgeAvailable:(NSString *)context {
  NSAssert(self.bridge != nil, @"Bridge is nil when %@", context);
}

- (instancetype)init {
  return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    _props = NotificationInboxViewNativeShadowNode::defaultSharedProps();

    Class bridgeClass = NSClassFromString(@"ReactNotificationInboxView");
    if (bridgeClass) {
      self.bridge = [[bridgeClass alloc] initWithContainerView:self];
      [self assertBridgeAvailable:@"creating ReactNotificationInboxView bridge instance"];
      [self.bridge setEventEmitter:self];
    }
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  [self assertBridgeAvailable:@"during layoutSubviews"];
  [self.bridge updateLayout:[NSValue valueWithCGRect:self.bounds]];
}

- (void)prepareForRecycle {
  [super prepareForRecycle];
  [self assertBridgeAvailable:@"during prepareForRecycle"];
  [self.bridge prepareForRecycle];
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<NotificationInboxViewNativeComponentDescriptor>();
}

@end

Class<RCTComponentViewProtocol> NotificationInboxViewNativeCls(void) {
  return RCTNotificationInboxViewNative.class;
}
