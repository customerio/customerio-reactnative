import Foundation

// Exists to allow mocking Date() in tests
// Not meant to be mocked. Use `DateUtilStub` in tests instead.
public protocol DateUtil {
    var now: Date { get }
}

// sourcery: InjectRegister = "DateUtil"
public class SdkDateUtil: DateUtil {
    public var now: Date {
        Date()
    }
}
