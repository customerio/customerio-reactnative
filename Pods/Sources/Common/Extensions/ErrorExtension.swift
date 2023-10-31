import Foundation

/**
 When creating custom errors, we usually just extend the `Error` class
 with `CustomStringConvertible` to add a `description` to the `Error`.

 The problem is that Swift's `Error` class does not expose
 `description` but only a different property `localizedDescription`.

 If someone takes your custom `Error` class and calls `localizedDescription`
 on it, the string will be `NameOfClass code 1`. Not your `description`.

 This is an easy way to fix that. All you need to do is
 extend your custom `Error` class with `LocalizedError` and done!
 */
public extension LocalizedError where Self: CustomStringConvertible {
    var errorDescription: String? {
        description
    }
}
