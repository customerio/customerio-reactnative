#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_REMAP_MODULE (NativeCustomerIO, CioRctWrapper, NSObject)

RCT_EXTERN_METHOD(initialize : (id)config args : (id _Nullable)args)
RCT_EXTERN_METHOD(identify : (NSString* _Nullable)userId traits : (NSDictionary* _Nullable)traits)
RCT_EXTERN_METHOD(clearIdentify)
RCT_EXTERN_METHOD(track : (NSString*)name properties : (NSDictionary* _Nullable)properties)
RCT_EXTERN_METHOD(screen : (NSString*)title properties : (NSDictionary* _Nullable)properties)
RCT_EXTERN_METHOD(setProfileAttributes : (NSDictionary*)attributes)
RCT_EXTERN_METHOD(setDeviceAttributes : (NSDictionary*)attributes)
RCT_EXTERN_METHOD(registerDeviceToken : (NSString*)token)
RCT_EXTERN_METHOD(deleteDeviceToken)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end
