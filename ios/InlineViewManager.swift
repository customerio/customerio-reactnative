import CioMessagingInApp
import React

// Create an instance of RCTViewManager, as required by RN. 
// Learn more about this manager: https://reactnative.dev/docs/native-components-ios
@objc(InlineViewManager)
class InlineViewManager: RCTViewManager {
    var gistView: GistView!

    override public static func requiresMainQueueSetup() -> Bool {
        return true
    }

  // This function's job is to return a new View instance. 
  override public func view() -> UIView! {
    // We want to display a WebView in the RN app. To do that, we can re-use the spike done for native iOS. 
    // To use the iOS spike, we need to create an instance of the GistView class and call startItUp() on it.
    gistView = GistView()
    gistView.startItUp() // In production code, we may not need to call a function on the GistView. This is only required for the current iOS spike code. 
    return gistView
  }
}