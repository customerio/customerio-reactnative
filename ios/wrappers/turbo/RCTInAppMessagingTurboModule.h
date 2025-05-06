//
//  RCTInAppMessagingTurboModule.h
//  customerio-reactnative
//
//  Created for CustomerIO React Native SDK
//

#import <CioMessagingInApp/CioMessagingInApp.h>
#import <Foundation/Foundation.h>
#import <InAppMessagingModuleSpec/InAppMessagingModuleSpec.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCTInAppMessagingTurboModule
    : NSObject <InAppMessagingModuleSpec, InAppEventListener>

@end

NS_ASSUME_NONNULL_END