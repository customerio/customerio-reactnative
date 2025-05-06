//
//  RCTCustomerIOTurboModuleProvider.mm
//  customerio-reactnative
//
//  Created for CustomerIO React Native SDK
//

#import "RCTCustomerIOTurboModuleProvider.h"
#import "RCTCustomerIOTurboModule.h"
#import "RCTInAppMessagingTurboModule.h"
#import "RCTPushMessagingTurboModule.h"
#import <React/RCTLog.h>

@implementation RCTCustomerIOTurboModuleProvider

// This method is called by React Native to get a TurboModule for a given name
- (id<RCTTurboModule>)getModuleForName:(const char *)name
                          wrapperClass:(Class)wrapperClass {
  NSString *moduleName = [NSString stringWithUTF8String:name];

  // Return the appropriate module based on the name
  if ([moduleName isEqualToString:@"CustomerIOModule"]) {
    return [[RCTCustomerIOTurboModule alloc] init];
  } else if ([moduleName isEqualToString:@"InAppMessagingModule"]) {
    return [[RCTInAppMessagingTurboModule alloc] init];
  } else if ([moduleName isEqualToString:@"PushMessagingModule"]) {
    return [[RCTPushMessagingTurboModule alloc] init];
  }

  // If the module name is not recognized, return nil
  return nil;
}

// This method is called by React Native to check if a module with a given name
// exists
- (BOOL)moduleIsAvailableForName:(const char *)name {
  NSString *moduleName = [NSString stringWithUTF8String:name];

  // Check if the module name is one of our TurboModules
  return [moduleName isEqualToString:@"CustomerIOModule"] ||
         [moduleName isEqualToString:@"InAppMessagingModule"] ||
         [moduleName isEqualToString:@"PushMessagingModule"];
}

@end