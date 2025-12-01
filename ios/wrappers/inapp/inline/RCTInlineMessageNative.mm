#import "RCTInlineMessageNative.h"
#import "ReactInlineMessageView.h"

#import <React/RCTConversions.h>
#import <React/RCTFabricComponentsPlugins.h>
#import <react/renderer/components/RNCustomerIOSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNCustomerIOSpec/EventEmitters.h>
#import <react/renderer/components/RNCustomerIOSpec/Props.h>
#import <react/renderer/components/RNCustomerIOSpec/RCTComponentViewHelpers.h>

using namespace facebook::react;

/// New architecture React Native view for inline messages
@interface RCTInlineMessageNative () <RCTInlineMessageNativeViewProtocol>
/// Bridge to Swift ReactInlineMessageView for platform-agnostic implementation
@property(nonatomic, strong) id bridge;
@end

@implementation RCTInlineMessageNative

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

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps {
  const auto &oldViewProps = *std::static_pointer_cast<InlineMessageNativeProps const>(_props);
  const auto &newViewProps = *std::static_pointer_cast<InlineMessageNativeProps const>(props);

  [self assertBridgeAvailable:@"during updateProps"];
  [self.bridge setupForReuse];

  // Handle react native props here
  if (oldViewProps.elementId != newViewProps.elementId) {
    NSString *elementId = [NSString stringWithCString:newViewProps.elementId.c_str() encoding:NSUTF8StringEncoding];
    [self assertBridgeAvailable:@"updating elementId prop"];
    [self.bridge setElementId:elementId];
  }

  [super updateProps:props oldProps:oldProps];
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

- (void)emitOnSizeChangeEvent:(NSDictionary *)event {
  [self handleOnSizeChangeEvent:event];
}

- (void)emitOnStateChangeEvent:(NSDictionary *)event {
  [self handleOnStateChangeEvent:event];
}

- (void)emitOnActionClickEvent:(NSDictionary *)event {
  [self handleOnActionClickEvent:event];
}

- (void)handleOnSizeChangeEvent:(NSDictionary *)event {
  if (_eventEmitter) {
    InlineMessageNativeEventEmitter::OnSizeChange result = InlineMessageNativeEventEmitter::OnSizeChange{};

    if (event[@"width"]) {
      result.width = [event[@"width"] doubleValue];
    }
    if (event[@"height"]) {
      result.height = [event[@"height"] doubleValue];
    }
    if (event[@"duration"]) {
      result.duration = [event[@"duration"] doubleValue];
    }

    self.eventEmitter.onSizeChange(result);
  }
}

- (void)handleOnStateChangeEvent:(NSDictionary *)event {
  if (_eventEmitter) {
    InlineMessageNativeEventEmitter::OnStateChange result = InlineMessageNativeEventEmitter::OnStateChange{};

    if (event[@"state"]) {
      result.state = std::string([[event[@"state"] description] UTF8String]);
    }

    self.eventEmitter.onStateChange(result);
  }
}

- (void)handleOnActionClickEvent:(NSDictionary *)event {
  if (_eventEmitter) {
    InlineMessageNativeEventEmitter::OnActionClick result = InlineMessageNativeEventEmitter::OnActionClick{};

    if (event[@"message"]) {
      NSDictionary *message = event[@"message"];
      InlineMessageNativeEventEmitter::OnActionClickMessage messageStruct =
          InlineMessageNativeEventEmitter::OnActionClickMessage{};

      if (message[@"messageId"]) {
        messageStruct.messageId = std::string([[message[@"messageId"] description] UTF8String]);
      }
      if (message[@"deliveryId"] && message[@"deliveryId"] != [NSNull null]) {
        messageStruct.deliveryId = std::string([[message[@"deliveryId"] description] UTF8String]);
      }
      if (message[@"elementId"] && message[@"elementId"] != [NSNull null]) {
        messageStruct.elementId = std::string([[message[@"elementId"] description] UTF8String]);
      }

      result.message = messageStruct;
    }

    if (event[@"actionValue"]) {
      result.actionValue = std::string([[event[@"actionValue"] description] UTF8String]);
    }
    if (event[@"actionName"]) {
      result.actionName = std::string([[event[@"actionName"] description] UTF8String]);
    }

    self.eventEmitter.onActionClick(result);
  }
}

// Event emitter convenience method
- (const InlineMessageNativeEventEmitter &)eventEmitter {
  return static_cast<const InlineMessageNativeEventEmitter &>(*_eventEmitter);
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<InlineMessageNativeComponentDescriptor>();
}

@end

Class<RCTComponentViewProtocol> InlineMessageNativeCls(void) {
  return RCTInlineMessageNative.class;
}
