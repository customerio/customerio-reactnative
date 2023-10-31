import Foundation

/**
 The keys for `KeyValueStorage`. Less error-prone then hard-coded strings.
 */
public enum KeyValueStorageKey: String {
    case identifiedProfileId
    case pushDeviceToken
    case httpRequestsPauseEnds
}
