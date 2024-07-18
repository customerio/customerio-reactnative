#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(CustomerioReactnative, NSObject)

RCT_EXTERN_METHOD(initialize: (nonnull NSDictionary *) env
                  configData : (NSDictionary *) configData
                  packageConfig: (nonnull NSDictionary *) packageConfig)

RCT_EXTERN_METHOD(identify: (nonnull NSString *) identifier
                  body : (NSDictionary *) body)

RCT_EXTERN_METHOD(clearIdentify)

RCT_EXTERN_METHOD(track: (nonnull NSString *) name
                  data : (NSDictionary *) data)

RCT_EXTERN_METHOD(setDeviceAttributes : (nonnull NSDictionary *) data)

RCT_EXTERN_METHOD(setProfileAttributes : (nonnull NSDictionary *) data)

RCT_EXTERN_METHOD(screen: (nonnull NSString *) name
                  data : (NSDictionary *) data)

RCT_EXTERN_METHOD(registerDeviceToken : (nonnull NSString *) token)

RCT_EXTERN_METHOD(deleteDeviceToken)

RCT_EXTERN_METHOD(showPromptForPushNotifications: (NSDictionary *) options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getPushPermissionStatus: (RCTPromiseResolveBlock) resolver
                  rejecter:(RCTPromiseRejectBlock)rejecter)

RCT_EXTERN_METHOD(trackNotificationResponseReceived : (nonnull NSDictionary *) payload])

RCT_EXTERN_METHOD(trackNotificationReceived : (nonnull NSDictionary *) payload])

@end

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@implementation UIApplication(CIOReactNative) 

static void injectSelector(Class newClass, SEL newSel, Class addToClass, SEL makeLikeSel) {
    Method newMeth = class_getInstanceMethod(newClass, newSel);
    IMP imp = method_getImplementation(newMeth);
    const char* methodTypeEncoding = method_getTypeEncoding(newMeth);

    BOOL successful = class_addMethod(addToClass, makeLikeSel, imp, methodTypeEncoding);
    if (!successful) {
        class_addMethod(addToClass, newSel, imp, methodTypeEncoding);
        newMeth = class_getInstanceMethod(addToClass, newSel);

        Method orgMeth = class_getInstanceMethod(addToClass, makeLikeSel);

        method_exchangeImplementations(orgMeth, newMeth);
    }
}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        method_exchangeImplementations(class_getInstanceMethod(self, @selector(setDelegate:)), class_getInstanceMethod(self, @selector(setCioReactNativeDelegate:)));
    });
}

- (void) setCioReactNativeDelegate:(id<UIApplicationDelegate>)delegate {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class delegateClass = [delegate class];
        injectSelector(self.class, @selector(cio_application:didFinishLaunchingWithOptions:),
                       delegateClass, @selector(application:didFinishLaunchingWithOptions:));
        
        [self setCioReactNativeDelegate:delegate]; // continue swizzle
    });
}

- (BOOL)cio_application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
    NSLog(@"Called cio_applicationDidFinishLaunching: %@", launchOptions);
    
    // continue swizzle
    if ([self respondsToSelector:@selector(cio_application:didFinishLaunchingWithOptions:)])
        return [self cio_application:application didFinishLaunchingWithOptions:launchOptions];
    
    return YES;
}

@end