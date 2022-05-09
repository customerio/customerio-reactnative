import Foundation
import CioTracking

@objc(CustomerioReactnative)
class CustomerioReactnative: NSObject {

    @objc(multiply:withB:withResolver:withRejecter:)
    func multiply(a: Float, b: Float, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        resolve(a*b)
    }
    
    @objc static func requiresMainQueueSetup() -> Bool {
        false
    }
    
    @objc(initialize:apiKey:region:)
    func initialize(siteId: String, apiKey: String, region :String) -> Void {
        
        CustomerIO.initialize(siteId: siteId, apiKey: apiKey, region: getLocation(from: region))
        // TODO: Add SDK configuration in Phase 3
        CustomerIO.config {
            $0.logLevel = .debug
            $0.autoTrackScreenViews = true
        }
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
