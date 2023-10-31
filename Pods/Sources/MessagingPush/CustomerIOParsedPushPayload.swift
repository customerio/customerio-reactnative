import CioInternalCommon
import Foundation
#if canImport(UserNotifications)
import UserNotifications

/**
 The content of a push notification. Single source of truth for getting properties of a push notification.
 */
public class CustomerIOParsedPushPayload {
    public static let cioAttachmentsPrefix = "cio_sdk_"

    public var title: String {
        get {
            mutableNotificationContent.title
        }
        set {
            mutableNotificationContent.title = newValue
        }
    }

    public var body: String {
        get {
            mutableNotificationContent.body
        }
        set {
            mutableNotificationContent.body = newValue
        }
    }

    public var deepLink: URL? {
        get {
            cio.push.link?.url
        }
        set {
            cioPush = cioPush.linkSet(newValue?.absoluteString)
        }
    }

    public var image: URL? {
        get {
            cio.push.image?.url
        }
        set {
            cioPush = cioPush.imageSet(newValue?.absoluteString)
        }
    }

    public var cioAttachments: [UNNotificationAttachment] {
        mutableNotificationContent.attachments.filter { $0.identifier.starts(with: Self.cioAttachmentsPrefix) }
    }

    public func addImage(localFilePath: URL) {
        guard let imageAttachment =
            try? UNNotificationAttachment(
                identifier: "\(Self.cioAttachmentsPrefix)\(String.random)",
                url: localFilePath,
                options: nil
            )
        else {
            return
        }

        var existingAttachments = mutableNotificationContent.attachments
        existingAttachments.append(imageAttachment)

        mutableNotificationContent.attachments = existingAttachments
    }

    private var cio: CioPushPayload {
        get {
            // Disable swiftlint rule because this class can't initialize without this being valid +
            // setter wont set unless a valid Object is created.
            // swiftlint:disable:next force_cast
            jsonAdapter.fromDictionary(mutableNotificationContent.userInfo["CIO"] as! [AnyHashable: Any])!
        }
        set {
            // assert we have a valid payload before we set it as the new value
            guard let newUserInfo = jsonAdapter.toDictionary(newValue) else {
                return
            }
            mutableNotificationContent.userInfo["CIO"] = newUserInfo
        }
    }

    private var cioPush: CioPushPayload.Push {
        get {
            cio.push
        }
        set {
            cio = CioPushPayload(push: newValue)
        }
    }

    private let jsonAdapter: JsonAdapter
    public let mutableNotificationContent: UNMutableNotificationContent
    public let notificationContent: UNNotificationContent

    public static func parse(
        notificationContent: UNNotificationContent,
        jsonAdapter: JsonAdapter
    ) -> CustomerIOParsedPushPayload? {
        let raw = notificationContent.userInfo

        guard let cioUserInfo = raw["CIO"] as? [AnyHashable: Any],
              let _: CioPushPayload = jsonAdapter.fromDictionary(cioUserInfo),
              let mutableNotificationContent = notificationContent.mutableCopy() as? UNMutableNotificationContent
        else {
            return nil
        }

        return CustomerIOParsedPushPayload(
            originalNotificationContent: notificationContent,
            mutableNotificationContent: mutableNotificationContent,
            jsonAdapter: jsonAdapter
        )
    }

    // Used when modifying push content before showing and for parsing after displaying.
    private init(
        originalNotificationContent: UNNotificationContent,
        mutableNotificationContent: UNMutableNotificationContent,
        jsonAdapter: JsonAdapter
    ) {
        self.notificationContent = originalNotificationContent
        self.mutableNotificationContent = mutableNotificationContent
        self.jsonAdapter = jsonAdapter
    }
}
#endif

struct CioPushPayload: Codable {
    let push: Push

    struct Push: Codable, AutoLenses {
        let link: String?
        let image: String?

        enum CodingKeys: String, CodingKey {
            case link
            case image
        }
    }

    enum CodingKeys: String, CodingKey {
        case push
    }
}
