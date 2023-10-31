import Foundation

class UserManager {
    let userTokenKey = "UserToken"
    let defaults = UserDefaults.standard

    func getUserToken() -> String? {
        defaults.string(forKey: userTokenKey)
    }

    func setUserToken(userToken: String) {
        defaults.set(userToken, forKey: userTokenKey)
    }

    func clearUserToken() {
        defaults.removeObject(forKey: userTokenKey)
    }
}
