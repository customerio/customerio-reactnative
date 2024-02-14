import Foundation
import UserNotifications

/*
 This class adds backwards compatability for the public data type, `CustomerIOParsedPushPayload`.
 To make our SDK more testable, we refactored our SDK codebase to de-couple it from the iOS `UserNotifications` framework. Part of that work was refactoring `CustomerIOParsedPushPayload`, but because this class is part of the public-API, we needed to provide a backwards comptible way to use it.
 */

// A push notification sent from Customer.io.
// Allows you to conveniently parse a push payload to get important information from the push.
public typealias CustomerIOParsedPushPayload = UNNotificationWrapper

// Add public properties that are part of the public API of `CustomerIOParsedPushPayload` that may be missing from the typealias type.
// The list of properties below was determined by viewing the public API tests in the test suite.
public extension CustomerIOParsedPushPayload {
    var deepLink: URL? {
        cioDeepLink?.url
    }

    var image: URL? {
        cioImage?.url
    }
}
