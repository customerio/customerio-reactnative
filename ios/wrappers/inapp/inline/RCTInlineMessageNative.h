// RCTViewComponentView.h transitively includes C++ code from React Native's Fabric renderer.
// When this header is imported from an Objective-C (.h) file, certain build phases
// (e.g., Clang dependency scanning, Swift bridging, and module indexing) parse it in
// pure Objective-C mode, where C++ constructs are not allowed.
//
// Wrapping the import in `#ifdef __cplusplus` ensures it is only visible when the file
// is compiled in Objective-C++ mode (.mm), preventing build failures.
#ifdef __cplusplus
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCTInlineMessageNative : RCTViewComponentView
@end

NS_ASSUME_NONNULL_END
#endif
