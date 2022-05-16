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
        CustomerIO.config {
            $0.logLevel = .debug
        }
    }
    
    /**
     Identify a customer, note that only one customer is identified at a time

     - Parameters:
     - identifier: unique ID of the customer.
     - body (Optional): attributes of a customer.
     */
    @objc(identify:body:)
    func identify(identifier: String, body: Dictionary<String, AnyHashable>?) -> Void {
    
        guard let data = body else {
            CustomerIO.shared.identify(identifier: identifier)
            return
        }
        CustomerIO.shared.identify(identifier: identifier, body: data)
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


extension Encodable {
  func asDictionary() throws -> [String: Any] {
    let data = try JSONEncoder().encode(self)
    guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
      throw NSError()
    }
    return dictionary
  }
}
