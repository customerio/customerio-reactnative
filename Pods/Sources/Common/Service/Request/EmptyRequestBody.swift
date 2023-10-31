import Foundation

/**
 Empty codable used to create an empty request body for a HTTP request.

 Exists to satisfy Swift generics. Swift generics requires at compile-time that it knows the concrete type
 being passed into a function. If we have a class with the following functions:
 ```
 func identify<Body: Encodable>(body: Body)
 func identify()
 ```

 The SDK code can have `identify()` call `identify(body)` by using `EmptyRequestBody()`.
 */
public struct EmptyRequestBody: Codable {
    public init() {}
}
