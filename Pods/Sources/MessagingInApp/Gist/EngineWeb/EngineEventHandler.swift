import Foundation
import UIKit

typealias EngineEventProperties = [String: AnyObject]

enum EngineEvent: String {
    case bootstrapped
    case routeLoaded
    case routeError
    case routeChanged
    case sizeChanged
    case tap
    case error
}

struct TapProperties {
    let name: String
    let action: String
    let system: Bool
}

enum EngineEventHandler {
    static func getTapProperties(properties: EngineEventProperties) -> TapProperties? {
        guard let parameters = properties["parameters"],
              let name = parameters["name"] as? String,
              let action = parameters["action"] as? String,
              let system = parameters["system"] as? Bool
        else {
            return nil
        }
        return TapProperties(name: name, action: action, system: system)
    }

    static func getSizeProperties(properties: EngineEventProperties) -> CGSize? {
        guard let parameters = properties["parameters"],
              let width = parameters["width"] as? CGFloat,
              let height = parameters["height"] as? CGFloat
        else {
            return nil
        }
        return CGSize(width: width, height: height)
    }

    static func getRouteChangedProperties(properties: EngineEventProperties) -> String? {
        extractRoute(properties: properties)
    }

    static func getRouteErrorProperties(properties: EngineEventProperties) -> String? {
        extractRoute(properties: properties)
    }

    static func getRouteLoadedProperties(properties: EngineEventProperties) -> String? {
        extractRoute(properties: properties)
    }

    private static func extractRoute(properties: EngineEventProperties) -> String? {
        guard let parameters = properties["parameters"],
              let route = parameters["route"] as? String
        else {
            return nil
        }
        return route
    }
}
