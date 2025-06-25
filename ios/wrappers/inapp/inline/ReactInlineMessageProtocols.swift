import Foundation

/// Protocol defining the interface for communication between ReactInlineMessageView and Objective-C classes
/// Provides a stable contract to minimize breaking changes when interfacing with Objective-C components
@objc public protocol ReactInlineMessageViewProtocol: NSObjectProtocol {
    /// Configures the event emitter for communicating with React Native
    func setEventEmitter(_ eventEmitter: ReactInlineMessageEventEmitterProtocol?)

    /// Sets the element id identifier for InlineMessageUIView
    func setElementId(_ elementId: String)

    /// Prepares view state before reuse in React Native render cycle
    func setupForReuse()

    /// Cleans up resources before view recycling
    func prepareForRecycle()

    /// Updates the view's layout based on new bounds from React Native
    func updateLayout(_ boundsValue: NSValue)
}

/// Protocol for communication between ReactInlineMessageView and Objective-C event emission classes
/// Provides a stable interface to minimize breaking changes when emitting events to React Native
@objc public protocol ReactInlineMessageEventEmitterProtocol: NSObjectProtocol {
    /// Emits size change events when the inline message dimensions change
    func emitOnSizeChangeEvent(_ event: NSDictionary)

    /// Emits state change events when the inline message state updates
    func emitOnStateChangeEvent(_ event: NSDictionary)
}
