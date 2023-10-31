import Foundation

public enum QueueTaskType: String {
    case trackDeliveryMetric
    case identifyProfile
    case trackEvent
    case registerPushToken
    case deletePushToken
    case trackPushMetric
}
