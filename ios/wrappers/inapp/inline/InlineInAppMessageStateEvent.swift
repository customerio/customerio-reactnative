import Foundation

/// States representing the loading and display status of inline messages.
/// This enum mirrors TypeScript InlineMessageState enum for consistency.
@objc enum InlineInAppMessageStateEvent: Int, CaseIterable {
    case loadingStarted
    case loadingFinished
    case noMessageToDisplay

    /**
     * Returns the string representation of the state that matches TypeScript enum values.
     */
    var stringValue: String {
        switch self {
        case .loadingStarted:
            return "LoadingStarted"
        case .loadingFinished:
            return "LoadingFinished"
        case .noMessageToDisplay:
            return "NoMessageToDisplay"
        }
    }
}
