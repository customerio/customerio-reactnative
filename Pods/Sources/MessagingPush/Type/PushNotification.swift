import Foundation

// A data type that represents a push notification.
// Note: This data class represents *all* push notifications, even those not sent by CIO.
public protocol PushNotification {
    // an id that uniquely identifies this push notification.
    // For push notifications sent by APN or FCM, this id gets populated by them with a random value.
    // For locally created notifications, this ID is provided by the app developer. So, the ID might be a hard-coded value and not unique between 2 pushes.
    var pushId: String { get }

    // Date when the push was delivered to the device.
    // Some subclasses of UserNotifications framework does not include a delivery date so we have to keep this optional.
    // Depending on the request that the framework makes to our SDK will determine if we get a date or not.
    var deliveryDate: Date? { get }

    var title: String { get set }
    var body: String { get set }
    var data: [AnyHashable: Any] { get set }

    // Attachments on a push notification are mostly used to display additional content on a push such as an image.
    var attachments: [PushAttachment] { get set }
}

public struct PushAttachment {
    public let identifier: String
    public let localFileUrl: URL
}

// Set of convenient properties for when a push was sent by Customer.io
public extension PushNotification {
    var cioAttachmentsPrefix: String {
        "cio_sdk_"
    }

    var cioDelivery: (id: String, token: String)? {
        guard let id = data["CIO-Delivery-ID"] as? String,
              let token = data["CIO-Delivery-Token"] as? String
        else {
            return nil
        }

        return (id: id, token: token)
    }

    var isPushSentFromCio: Bool {
        cioDelivery != nil
    }

    private var cioPayload: [AnyHashable: Any]? {
        get {
            data["CIO"] as? [AnyHashable: Any]
        }
        set {
            data["CIO"] = newValue
        }
    }

    private var cioPushPayload: [AnyHashable: Any]? {
        get {
            cioPayload?["push"] as? [AnyHashable: Any]
        }
        set {
            cioPayload?["push"] = newValue
        }
    }

    var cioImage: String? { // a https URL to point to a remote image
        get {
            cioPushPayload?["image"] as? String
        }
        set {
            cioPushPayload?["image"] = newValue
        }
    }

    var cioDeepLink: String? {
        get {
            cioPushPayload?["link"] as? String
        }
        set {
            cioPushPayload?["link"] = newValue
        }
    }

    // Allows our SDK to find attachments added by the SDK. Needed for deleting image files from the file system during push cleanup, for example.
    var cioAttachments: [PushAttachment] {
        get {
            attachments.filter {
                $0.identifier.starts(with: cioAttachmentsPrefix)
            }
        }
        set {
            attachments = newValue
        }
    }

    // After an image is downloaded, this points to the local file on the device where the image file is located.
    var cioRichPushImageFile: URL? {
        get {
            // At this time, an image is the only attachment our SDK adds to a push.
            cioAttachments.first?.localFileUrl
        }
        set {
            guard let newValue = newValue else {
                cioAttachments = []
                return
            }

            cioAttachments = [
                PushAttachment(
                    identifier: "\(cioAttachmentsPrefix)\(String.random)",
                    localFileUrl: newValue
                )
            ]
        }
    }
}
