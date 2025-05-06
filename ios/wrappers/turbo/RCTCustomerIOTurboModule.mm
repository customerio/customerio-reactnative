//
//  RCTCustomerIOTurboModule.mm
//  customerio-reactnative
//
//  Created for CustomerIO React Native SDK
//

#import "RCTCustomerIOTurboModule.h"
#import <CioAnalytics/CioAnalytics.h>
#import <CioDataPipelines/CioDataPipelines.h>
#import <CioInternalCommon/CioInternalCommon.h>
#import <React/RCTUtils.h>

@interface RCTCustomerIOTurboModule ()
@property(nonatomic, strong) CioInternalCommon.Logger *logger;
@end

@implementation RCTCustomerIOTurboModule

RCT_EXPORT_MODULE(CustomerIOModule)

- (id)init {
  if (self = [super init]) {
    _logger = DIGraphShared.shared.logger;
  }
  return self;
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::CustomerIOModuleSpecJSI>(params);
}

#pragma mark - CustomerIO Core Methods

- (void)initialize:(NSDictionary *)config
       packageInfo:(NSDictionary *)packageInfo {
  @try {
    NSString *packageSource = packageInfo[@"packageSource"];
    NSString *packageVersion = packageInfo[@"packageVersion"];

    if (packageSource && packageVersion) {
      DIGraphShared.shared.override(value : [[CustomerIOSdkClient alloc]
                                        initWithSource:packageSource
                                            sdkVersion:packageVersion],
                                    forType : SdkClient.self);
    }

    SDKConfigBuilder *sdkConfigBuilder =
        [SDKConfigBuilder createFromDictionary:config];
    [CustomerIO initializeWithConfig:[sdkConfigBuilder build]];

    [self.logger
        debugWithMessage:
            [NSString stringWithFormat:
                          @"CustomerIO SDK (%@ %@) initialized with config: %@",
                          packageSource ?: @"", packageVersion ?: @"", config]];
  } @catch (NSException *exception) {
    [self.logger
        errorWithMessage:[NSString
                             stringWithFormat:@"Initializing CustomerIO SDK "
                                              @"failed with error: %@",
                                              exception.reason]];
  }
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits {
  if (userId) {
    [CustomerIO.shared identifyWithUserId:userId traits:traits];
  } else if (traits) {
    @try {
      JSON *traitsJson = [[JSON alloc] initWithDictionary:traits];
      [CustomerIO.shared identifyWithTraits:traitsJson];
    } @catch (NSException *exception) {
      [self.logger
          errorWithMessage:
              [NSString stringWithFormat:@"Unable to parse traits to JSON: %@",
                                         traits]];
    }
  } else {
    [self.logger
        errorWithMessage:@"Provide id or traits to identify a user profile."];
  }
}

- (void)clearIdentify {
  [CustomerIO.shared clearIdentify];
}

- (void)track:(NSString *)name properties:(NSDictionary *)properties {
  [CustomerIO.shared trackWithName:name properties:properties];
}

- (void)screen:(NSString *)title properties:(NSDictionary *)properties {
  [CustomerIO.shared screenWithTitle:title properties:properties];
}

- (void)setProfileAttributes:(NSDictionary *)attributes {
  CustomerIO.shared.profileAttributes = attributes;
}

- (void)setDeviceAttributes:(NSDictionary *)attributes {
  CustomerIO.shared.deviceAttributes = attributes;
}

- (void)registerDeviceToken:(NSString *)token {
  [CustomerIO.shared registerDeviceToken:token];
}

- (void)deleteDeviceToken {
  [CustomerIO.shared deleteDeviceToken];
}

@end