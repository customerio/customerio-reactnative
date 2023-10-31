import Foundation

// allows us to more easily have automated tests with threading
public protocol ThreadUtil {
    func runBackground(_ block: @escaping () -> Void)
    func runMain(_ block: @escaping () -> Void)
}

// sourcery: InjectRegister = "ThreadUtil"
public class CioThreadUtil: ThreadUtil {
    public func runMain(_ block: @escaping () -> Void) {
        DispatchQueue.main.async(execute: block)
    }

    public func runBackground(_ block: @escaping () -> Void) {
        DispatchQueue.global(qos: .background).async(execute: block)
    }
}
