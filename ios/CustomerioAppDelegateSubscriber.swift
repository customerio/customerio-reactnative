import Foundation
import ExpoModulesCore

public class CustomerioAppDelegateSubscriber : ExpoAppDelegateSubscriber {
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      print("Debugger invoked")
    }

    
}
