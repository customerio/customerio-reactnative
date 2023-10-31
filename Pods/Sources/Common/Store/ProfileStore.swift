import Foundation

public protocol ProfileStore: AutoMockable {
    var identifier: String? { get set }
}

// sourcery: InjectRegister = "ProfileStore"
public class CioProfileStore: ProfileStore {
    private let keyValueStorage: KeyValueStorage

    init(keyValueStorage: KeyValueStorage) {
        self.keyValueStorage = keyValueStorage
    }

    public var identifier: String? {
        get {
            keyValueStorage.string(.identifiedProfileId)
        }
        set {
            keyValueStorage.setString(newValue, forKey: .identifiedProfileId)
        }
    }
}
