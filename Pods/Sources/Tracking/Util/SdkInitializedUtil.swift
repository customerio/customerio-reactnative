import CioInternalCommon
import Foundation

public protocol SdkInitializedUtil: AutoMockable {
    var customerio: CustomerIO? { get }
    var isInitlaized: Bool { get }
    var postInitializedData: (siteId: String, diGraph: DIGraph)? { get }
}

// Used by SDK modules to determine if the SDK has been initialized or not.
// This is the safe way to get data you need *after* the SDK is initialized.
public class SdkInitializedUtilImpl: SdkInitializedUtil {
    // Try to not use dependencies in this class as it's contructed before
    // DI graph could be populated. So, production code calls this constructor.
    public init() {}

    public var customerio: CustomerIO? {
        guard isInitlaized else { return nil }

        return CustomerIO.shared
    }

    public var isInitlaized: Bool {
        CustomerIO.shared.diGraph != nil
    }

    public var postInitializedData: (siteId: String, diGraph: DIGraph)? {
        guard let siteId = CustomerIO.shared.siteId,
              let diGraph = CustomerIO.shared.diGraph
        else {
            return nil
        }

        return (siteId: siteId, diGraph: diGraph)
    }
}
