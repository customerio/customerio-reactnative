import CioInternalCommon
import Foundation

/// Preconditions and utility functions for React Native wrapper
public enum Preconditions {
    /// Throws a runtime exception in debug builds and logs a warning in release builds if a method
    /// that is only supported on Android is called from iOS.
    ///
    /// Use this to guard any platform-specific methods that are not expected to called on iOS from TypeScript.
    public static func unsupportedOnIOS(methodName: String) {
        let message = "'\(methodName)' is unsupported on iOS and should not be called."

        #if DEBUG
        fatalError(message)
        #else
        let logger = DIGraphShared.shared.logger
        logger.error(message)
        #endif
    }
}
