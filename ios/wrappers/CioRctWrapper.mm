#import <React/RCTBridgeModule.h>


@interface RCT_EXTERN_REMAP_MODULE(NativeCustomerIO, CioRctWrapper, NSObject)

RCT_EXTERN_METHOD(initialize:(id)config logLevel:(NSString *)logLevel)
RCT_EXTERN_METHOD(identify:(NSString *)identify traits:(NSDictionary *)traits)
RCT_EXTERN_METHOD(clearIdentify)
RCT_EXTERN_METHOD(track:(NSString *)name properties:(NSDictionary *)properties)
RCT_EXTERN_METHOD(screen:(NSString *)title category: (NSString *)category properties:(NSDictionary *))
RCT_EXTERN_METHOD(setProfileAttributes: (NSDictionary *)attributes)
RCT_EXTERN_METHOD(setDeviceAttributes: (NSDictionary *)attributes)
RCT_EXTERN_METHOD(registerDeviceToken: (NSString *)identify)
RCT_EXTERN_METHOD(deleteDeviceToken)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end
