import Foundation
import CioTracking

@objc(CustomerioReactnative)
class CustomerioReactnative: NSObject {

    @objc static func requiresMainQueueSetup() -> Bool {
        false /// false because our native module's initialization does not require access to UIKit
    }
    
    /**
     Initialize the package before sending any calls to the package
     */
    @objc(initialize:apiKey:region:)
    func initialize(siteId: String, apiKey: String, region :String) -> Void {
        CustomerIO.initialize(siteId: siteId, apiKey: apiKey, region: getLocation(from: region))
    }
    
    /**
     Identify a customer, note that only one customer is identified at a time

     - Parameters:
     - identifier: unique ID of the customer.
     - body (Optional): attributes of a customer.
     */
    @objc(identify:body:)
    func identify(identifier: String, body: [AnyHashable: Any]?) -> Void {
    
        // TODO : Encodable type, would that really matter with react native?
        if let body = body as? [String: Any] {
            CustomerIO.shared.identify(identifier: identifier, body: body)
        } else {
            CustomerIO.shared.identify(identifier: identifier)
        }
    }
    
    /**
     To stop identifying the user.
     Once the identity is cleared then the user can not be tracked, hence no events/activities are sent to the workspace
     */
    @objc(clearIdentify)
    func clearIdentify() {
        CustomerIO.shared.clearIdentify()
    }
    
    private func getLocation(from regionStr : String) -> Region{
        switch regionStr {
        case "US" :
            return Region.US
        case "EU" :
            return Region.EU
        default:
            return Region.US
        }
    }
}
