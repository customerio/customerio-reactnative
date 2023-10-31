import Foundation

public protocol HooksManager: AutoMockable {
    func add(key: HookModule, provider: ModuleHookProvider)
    var profileIdentifyHooks: [ProfileIdentifyHook] { get }
    var screenViewHooks: [ScreenTrackingHook] { get }
}

public enum HookModule: String {
    case tracking
    case messagingPush
    case messagingInApp
}

/*
 Singleton because we are storing objects in-memory set at runtime.

 As long as `ModuleHookProvider` subclasses are limiting thier use
 of singletons, it's OK for this class to be one.
 */
// sourcery: InjectRegister = "HooksManager"
// sourcery: InjectSingleton
public class CioHooksManager: HooksManager {
    private var hookProviders: [HookModule: ModuleHookProvider] = [:]

    /// using key/value pairs enforces that there is only 1 hook provider for each
    /// SDK without having duplicates.
    public func add(key: HookModule, provider: ModuleHookProvider) {
        hookProviders[key] = provider
    }

    public var profileIdentifyHooks: [ProfileIdentifyHook] {
        hookProviders.filter { $0.value.profileIdentifyHook != nil }.map { $0.value.profileIdentifyHook! }
    }

    public var screenViewHooks: [ScreenTrackingHook] {
        hookProviders.filter { $0.value.screenTrackingHook != nil }.map { $0.value.screenTrackingHook! }
    }
}
