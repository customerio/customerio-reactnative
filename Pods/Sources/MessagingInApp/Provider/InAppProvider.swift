import CioInternalCommon
import Foundation

// wrapper around Gist SDK to make it mockable
protocol InAppProvider: AutoMockable {
    func initialize(siteId: String, region: Region, delegate: GistDelegate, enableLogging: Bool)
    func setProfileIdentifier(_ id: String)
    func clearIdentify()
    func setRoute(_ route: String)
    func dismissMessage()
}

// sourcery: InjectRegister = "InAppProvider"
class GistInAppProvider: InAppProvider {
    func initialize(siteId: String, region: Region, delegate: GistDelegate, enableLogging: Bool = false) {
        Gist.shared.setup(siteId: siteId, dataCenter: region.rawValue, logging: enableLogging)
        Gist.shared.delegate = delegate
    }

    func setProfileIdentifier(_ id: String) {
        Gist.shared.setUserToken(id)
    }

    func clearIdentify() {
        Gist.shared.clearUserToken()
    }

    func setRoute(_ route: String) {
        Gist.shared.setCurrentRoute(route)
    }

    func dismissMessage() {
        Gist.shared.dismissMessage()
    }
}
