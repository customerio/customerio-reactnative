#import <React/RCTLog.h>
#import <React/RCTViewManager.h>

// After making the InlineViewManager, we need to expose it to React Native. 
// By using RCT_ macros, we are telling React Native that we want to expose this class along with its methods and properties to JavaScript.

@interface RCT_EXTERN_REMAP_MODULE(InlineViewManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(route, NSString);
RCT_EXPORT_VIEW_PROPERTY(props, NSDictionary);
RCT_EXPORT_VIEW_PROPERTY(config, NSDictionary);

@end