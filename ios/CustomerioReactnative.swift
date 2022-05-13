import Foundation
import CioTracking

@objc(CustomerioReactnative)
class CustomerioReactnative: NSObject {

    @objc static func requiresMainQueueSetup() -> Bool {
        false
    }
    
    @objc(initialize:apiKey:region:)
    func initialize(siteId: String, apiKey: String, region :String) -> Void {
        CustomerIO.initialize(siteId: siteId, apiKey: apiKey, region: getLocation(from: region))
    }
    
    @objc(identify:body:)
    func identify(identifier: String, body: [AnyHashable: Any]?) -> Void {
    
        // TODO : Encodable type, would that really matter with react native?
        if let body = body as? [String: Any] {
            CustomerIO.shared.identify(identifier: identifier, body: body)
        } else {
            CustomerIO.shared.identify(identifier: identifier)
        }
    }
    
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
