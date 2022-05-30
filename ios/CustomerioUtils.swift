import Foundation
import CioTracking



extension Region {
    static func getLocation(from regionStr : String) -> Region{
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

extension CioLogLevel {
    static func getLogValue(for value : Int) -> CioLogLevel {
        
        switch value {
        case 1:
            return .none
        case 2:
            return .error
        case 3:
            return .info
        case 4:
            return .debug
        default:
            return .error
        }
    }
}
