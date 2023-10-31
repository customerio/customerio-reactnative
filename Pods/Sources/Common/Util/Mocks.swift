import Foundation

// Mock classes are generated automatically in this project.
// To make using mocks easier in our test classes, this class exists to manage all of the mocks in the project.
//
// This class is only used for tests but must exist in `Common` module because mock classes are generated in the source
// code
// directory and not the test code directory of the project.
public class Mocks {
    public static var shared: Mocks = .init()

    private var mocks: [Mock] = []
    private init() {}

    // This gets called automatically by the automatically generated mock classes code.
    public func add(mock: Mock) {
        mocks.append(mock)
    }

    // Call this function in test teardown to reset the state of all mocks in your test.
    public func resetAll() {
        mocks.forEach {
            $0.resetMock()
        }
    }
}

// All automatically generated mocks classes inherit this protocol automatically.
public protocol Mock {
    func resetMock()
}
