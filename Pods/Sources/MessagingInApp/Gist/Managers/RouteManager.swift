import Foundation

class RouteManager {
    private static var currentRoute = ""

    static func getCurrentRoute() -> String {
        currentRoute
    }

    static func setCurrentRoute(_ currentRoute: String) {
        self.currentRoute = currentRoute
        Logger.instance.info(message: "Route changed to: \(currentRoute)")
    }

    static func clearCurrentRoute() {
        currentRoute = ""
        Logger.instance.info(message: "Route cleared")
    }
}
