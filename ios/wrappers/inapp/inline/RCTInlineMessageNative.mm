#ifdef RCT_NEW_ARCH_ENABLED

#import "RCTInlineMessageNative.h"
#import "customerio_reactnative-Swift.h"

#import <React/RCTConversions.h>
#import <react/renderer/components/RNCustomerIOSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNCustomerIOSpec/EventEmitters.h>
#import <react/renderer/components/RNCustomerIOSpec/Props.h>
#import <react/renderer/components/RNCustomerIOSpec/RCTComponentViewHelpers.h>

using namespace facebook::react;

@class ReactInlineMessageView;

/// New architecture React Native view for inline messages
@interface RCTInlineMessageNative () <RCTInlineMessageNativeViewProtocol, ReactInlineMessageEventEmitterProtocol>
/// Bridge to Swift ReactInlineMessageView for platform-agnostic implementation
@property(nonatomic, strong) id<ReactInlineMessageViewProtocol> bridge;
@end

@implementation RCTInlineMessageNative

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
        NSAssert(self.bridge != nil, @"Failed to create ReactInlineMessageView bridge instance");
        // Set up event handlers for new architecture only if bridge was created successfully
        if (self.bridge) {
          [self.bridge setEventEmitter:self];
        }
      }
    }
  }
  return self;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps {
  const auto &oldViewProps = *std::static_pointer_cast<InlineMessageNativeProps const>(_props);
  const auto &newViewProps = *std::static_pointer_cast<InlineMessageNativeProps const>(props);

  [self assertBridgeAvailable:@"during prepareView"];
  if (self.bridge) {
    [self.bridge setupForReuse];
  }

  // Handle react native props here
  if (oldViewProps.elementId != newViewProps.elementId) {
    NSString *elementId = [NSString stringWithCString:newViewProps.elementId.c_str() encoding:NSUTF8StringEncoding];
    [self assertBridgeAvailable:@"updating elementId prop"];
    if (self.bridge) {
      [self.bridge setElementId:elementId];
    }
  }

  [super updateProps:props oldProps:oldProps];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  [self assertBridgeAvailable:@"during layoutSubviews"];
  if (self.bridge) {
    [self.bridge updateLayout:[NSValue valueWithCGRect:self.bounds]];
  }
}

- (void)prepareForRecycle {
  [super prepareForRecycle];
  [self assertBridgeAvailable:@"during prepareForRecycle"];
  if (self.bridge) {
    [self.bridge prepareForRecycle];
  }
}

- (void)emitOnSizeChangeEvent:(NSDictionary *)event {
  NSParameterAssert(event != nil);
  [self handleOnSizeChangeEvent:event];
}

- (void)emitOnStateChangeEvent:(NSDictionary *)event {
  NSParameterAssert(event != nil);
  [self handleOnStateChangeEvent:event];
}

- (void)handleOnSizeChangeEvent:(NSDictionary *)event {
  NSParameterAssert(event != nil);
  NSAssert(_eventEmitter != nullptr, @"Event emitter is null when handling size change event");

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
  NSParameterAssert(event != nil);
  NSAssert(_eventEmitter != nullptr, @"Event emitter is null when handling state change event");

  if (_eventEmitter) {
    InlineMessageNativeEventEmitter::OnStateChange result = InlineMessageNativeEventEmitter::OnStateChange{};

    if (event[@"state"]) {
      result.state = std::string([[event[@"state"] description] UTF8String]);
    }

    self.eventEmitter.onStateChange(result);
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

#endif
