#import <Foundation/Foundation.h>

#ifndef RCTCustomerIOUtils_h
#define RCTCustomerIOUtils_h

/// Utility macro for asserting object availability in React Native wrappers
#define RCT_ASSERT_NOT_NIL(object, label, context) \
  NSAssert((object) != nil, @"%@ is nil when %@", (label), (context))

/// Alias for bridge-specific assertions
#define RCT_ASSERT_BRIDGE_AVAILABLE(bridge, context) \
  RCT_ASSERT_NOT_NIL((bridge), @"Bridge", (context))

/// Logs a warning for methods that are only needed in legacy architecture
#define RCT_LEGACY_ARCH_WARNING(methodName) \
  NSLog(@"Warning: '%@' is not required in the New Architecture and should not be called.", \
        @ #methodName)

#endif /* RCTCustomerIOUtils_h */
