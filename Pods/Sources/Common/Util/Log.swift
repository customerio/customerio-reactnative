import Foundation
#if canImport(os)
import os.log
#endif

/// mockable logger + abstract that allows you to log to multiple places if you wish
public protocol Logger: AutoMockable {
    /// the noisey log level. Feel free to spam this log level with any
    /// information about the SDK that would be useful for debugging the SDK.
    func debug(_ message: String)
    /// Not noisy log messages. Good for general information such as
    /// when the background queue begins and ends running but use `debug`
    /// for the status of each background queue task running.
    func info(_ message: String)
    /// the SDK is in an unstable state that you want to notify
    /// the customer or our development team about.
    func error(_ message: String)
}

/// none - no logs will be made
/// error - only log when there is an error in the SDK (default)
/// info - basic SDK informion. Somewhat noisy. Recommended to start debugging SDK.
/// debug - most noisy. See all of the logs made from the SDK.
public enum CioLogLevel: String, CaseIterable {
    case none
    case error
    case info
    case debug

    #if canImport(os)
    func shouldLog(_ level: CioLogLevel) -> Bool {
        switch self {
        case .none: return false
        case .error:
            return level == .error
        case .info:
            return level == .error || level == .info
        case .debug:
            return true
        }
    }

    var osLogLevel: OSLogType {
        switch self {
        case .none: return .info
        case .error: return .error
        case .info: return .info
        case .debug: return .debug
        }
    }
    #endif
}

// log messages to console.
// sourcery: InjectRegister = "Logger"
public class ConsoleLogger: Logger {
    // allows filtering in Console mac app
    public static let logSubsystem = "io.customer.sdk"
    public static let logCategory = "CIO"

    private let sdkConfig: SdkConfig

    private var abbreviatedSiteId: String {
        sdkConfig.siteId.getFirstNCharacters(5)
    }

    private var minLogLevel: CioLogLevel {
        sdkConfig.logLevel
    }

    init(sdkConfig: SdkConfig) {
        self.sdkConfig = sdkConfig
    }

    private func printMessage(_ message: String, _ level: CioLogLevel) {
        if !minLogLevel.shouldLog(level) { return }

        let messageToPrint = "(siteid:\(abbreviatedSiteId)) \(message)"

        ConsoleLogger.logMessageToConsole(messageToPrint, level: level)
    }

    public func debug(_ message: String) {
        printMessage(message, .debug)
    }

    public func info(_ message: String) {
        printMessage("ℹ️ \(message)", .info)
    }

    public func error(_ message: String) {
        printMessage("🛑 \(message)", .error)
    }

    public static func logMessageToConsole(_ message: String, level: CioLogLevel) {
        #if canImport(os)
        // Unified logging for Swift. https://www.avanderlee.com/workflow/oslog-unified-logging/
        // This means we can view logs in xcode console + Console app.
        if #available(iOS 14, *) {
            let logger = os.Logger(subsystem: self.logSubsystem, category: self.logCategory)
            logger.log(level: level.osLogLevel, "\(message, privacy: .public)")
        } else {
            let logger = OSLog(subsystem: logSubsystem, category: logCategory)
            os_log("%{public}@", log: logger, type: level.osLogLevel, message)
        }
        #else
        // At this time, Linux cannot use `os.log` or `OSLog`. Instead, use: https://github.com/apple/swift-log/
        // As we don't officially support Linux at this time, no need to add a dependency to the project.
        // therefore, we are not logging if can't import os.log
        #endif
    }
}

// Log messages to customers when the SDK is not initialized.
// Great for alerts when the SDK may not be setup correctly.
// Since the SDK is not initialized, dependencies graph is not created.
// Therefore, this is just a function that's available at the top-level available to all
// of the SDK without the use of dependencies.
public func sdkNotInitializedAlert(_ message: String) {
    ConsoleLogger.logMessageToConsole("⚠️ \(message)", level: .error)
}

extension CioLogLevel {
    static func getLogLevel(for value: String) -> CioLogLevel? {
        switch value.lowercased() {
        case CioLogLevel.none.rawValue:
            return CioLogLevel.none
        case CioLogLevel.error.rawValue:
            return .error
        case CioLogLevel.info.rawValue:
            return .info
        case CioLogLevel.debug.rawValue:
            return .debug
        default:
            return nil
        }
    }
}
