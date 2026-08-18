import Foundation
import Darwin

public final class FileLifecycleTraceSink: LifecycleTraceSink {
    public static let receiptPathSuffix = ".receipt.json"

    private let handle: FileHandle
    private let receiptURL: URL

    public init?(path: String) {
        let url = URL(fileURLWithPath: path)
        let receiptURL = URL(fileURLWithPath: path + Self.receiptPathSuffix)
        let manager = FileManager.default
        let parent = url.deletingLastPathComponent()
        guard !manager.fileExists(atPath: receiptURL.path),
              let parentValues = try? parent.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey]),
              parentValues.isDirectory == true,
              parentValues.isSymbolicLink != true else {
            return nil
        }
        if manager.fileExists(atPath: path) {
            guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey]),
                  values.isRegularFile == true,
                  values.isSymbolicLink != true,
                  (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) == 0 else {
                return nil
            }
        } else {
            guard manager.createFile(atPath: path, contents: nil) else {
                return nil
            }
        }
        guard let handle = try? FileHandle(forWritingTo: url) else { return nil }
        self.handle = handle
        self.receiptURL = receiptURL
    }

    deinit {
        handle.closeFile()
    }

    public func write(line: String) -> Bool {
        guard let data = (line + "\n").data(using: .utf8) else { return false }
        return data.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return data.isEmpty }
            var offset = 0
            while offset < bytes.count {
                let written = Darwin.write(
                    handle.fileDescriptor,
                    baseAddress.advanced(by: offset),
                    bytes.count - offset
                )
                if written < 0 {
                    if errno == EINTR { continue }
                    return false
                }
                guard written > 0 else { return false }
                offset += written
            }
            return true
        }
    }

    public func writeReceipt(json: String) -> Bool {
        guard let data = (json + "\n").data(using: .utf8) else { return false }
        do {
            try data.write(to: receiptURL, options: .withoutOverwriting)
            return true
        } catch {
            return false
        }
    }
}

/// Process-wide ownership for the single Swift stream declared by a capture manifest.
public enum LifecycleTraceHarness {
    private final class State: @unchecked Sendable {
        let lock = NSLock()
        var recorder: LifecycleTraceRecorder?
        var endCleanups: [() -> Void] = []
    }

    private static let state = State()

    public static var sharedRecorder: LifecycleTraceRecorder? {
        state.lock.lock()
        defer { state.lock.unlock() }
        return state.recorder
    }

    /// Configures the recorder only when the harness supplies a complete canonical context.
    @discardableResult
    public static func configureFromEnvironment(
        sink fallbackSink: @autoclosure () -> LifecycleTraceSink,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        processID: Int = Int(ProcessInfo.processInfo.processIdentifier),
        bufferCapacity: Int = 256
    ) -> LifecycleTraceRecorder? {
        state.lock.lock()
        defer { state.lock.unlock() }
        if let recorder = state.recorder { return recorder }
        guard let context = context(environment: environment, processID: processID), context.runtime == .swift else {
            fallbackSink().write(line: "CIO-LIFECYCLE-DIAGNOSTIC disabled: invalid or incomplete harness context")
            return nil
        }
        let sink: LifecycleTraceSink
        if let outputPath = environment["CIO_LIFECYCLE_OUTPUT_PATH"] {
            guard !outputPath.isEmpty, let fileSink = FileLifecycleTraceSink(path: outputPath) else {
                fallbackSink().write(line: "CIO-LIFECYCLE-DIAGNOSTIC disabled: unsafe or nonempty output path")
                return nil
            }
            sink = fileSink
        } else {
            sink = fallbackSink()
        }
        let configured = LifecycleTraceRecorder(
            context: context,
            sink: sink,
            bufferCapacity: bufferCapacity
        )
        state.recorder = configured
        return configured
    }

    @discardableResult
    public static func startScenario() -> Bool {
        let hasSceneManifest = Bundle.main.object(forInfoDictionaryKey: "UIApplicationSceneManifest") != nil
        return sharedRecorder?.startScenario(
            observation: LifecycleTraceObservation(
                flags: [.sceneManifestActive: hasSceneManifest]
            )
        ) ?? false
    }

    /// Records a canonical host or Customer.io URL-routing seat.
    public static func recordURLRoute(
        callback: LifecycleTraceCallback,
        phase: LifecycleTracePhase,
        evidence: LifecycleTraceObservation,
        routingResult: LifecycleTraceRoutingResult? = nil
    ) {
        let attribution: (owner: LifecycleTraceOwner, kind: LifecycleTraceKind)
        switch callback {
        case .hostRouteURL:
            attribution = (.host, .hostRouting)
        case .customerIORouteDeepLink:
            attribution = (.customerIOSDK, .sdkRouting)
        default:
            return
        }
        if let routingResult = routingResult {
            sharedRecorder?.record(
                callback: callback,
                owner: attribution.owner,
                kind: attribution.kind,
                phase: phase,
                observations: evidence,
                LifecycleTraceEvidence.observe(routingResult: routingResult)
            )
        } else {
            sharedRecorder?.record(
                callback: callback,
                owner: attribution.owner,
                kind: attribution.kind,
                phase: phase,
                observations: evidence
            )
        }
    }

    /// Closes a scenario after an already-instrumented terminal seat and emits its receipt.
    public static func endScenario(after terminal: LifecycleTraceTerminal) {
        guard let recorder = sharedRecorder else { return }
        let accepted = recorder.endScenario(after: terminal) { _ in
            handleEndCompletion()
        }
        guard accepted else { return }
    }

    static func handleEndCompletion() {
        runEndCleanups()
    }

    static func registerEndCleanup(_ cleanup: @escaping () -> Void) {
        state.lock.lock()
        state.endCleanups.append(cleanup)
        state.lock.unlock()
    }

    private static func runEndCleanups() {
        state.lock.lock()
        let cleanups = state.endCleanups
        state.endCleanups.removeAll()
        state.lock.unlock()
        cleanups.forEach { $0() }
    }

    private static func context(
        environment: [String: String],
        processID: Int
    ) -> LifecycleTraceContext? {
        let value: (String) -> String? = { environment["CIO_LIFECYCLE_\($0)"] }
        guard let manifestID = value("MANIFEST_ID"),
              let runID = value("RUN_ID"),
              let streamID = value("STREAM_ID"),
              let processInstanceID = value("PROCESS_INSTANCE_ID"),
              let scenarioValue = value("SCENARIO"),
              let scenario = LifecycleTraceScenario(rawValue: scenarioValue),
              let evidenceValue = value("EVIDENCE_LEVEL"),
              let evidence = LifecycleTraceEvidenceLevel(rawValue: evidenceValue),
              let hostTopologyValue = value("HOST_TOPOLOGY"),
              let hostTopology = LifecycleTraceHostTopology(rawValue: hostTopologyValue),
              let activationOccurrenceIdentity = value("ACTIVATION_OCCURRENCE_ID"),
              let integrationValue = value("INTEGRATION"),
              let integration = LifecycleTraceIntegration(rawValue: integrationValue),
              let runtimeValue = value("RUNTIME"),
              let runtime = LifecycleTraceRuntime(rawValue: runtimeValue),
              let providerValue = value("PROVIDER"),
              let provider = LifecycleTraceProvider(rawValue: providerValue) else {
            return nil
        }
        return LifecycleTraceContext(
            manifestID: manifestID,
            runID: runID,
            streamID: streamID,
            processID: processID,
            processInstanceID: processInstanceID,
            integration: integration,
            runtime: runtime,
            provider: provider,
            scenario: scenario,
            evidenceLevel: evidence,
            hostTopology: hostTopology,
            activationOccurrenceIdentity: activationOccurrenceIdentity
        )
    }
}

/// In-process observation bridge for generated fixtures that can import the support module.
public enum LifecycleTraceProbe {
    public static let notificationName = Notification.Name("io.customer.lifecycle-trace.probe.v1")
    public static let seatKey = "seat"
    public static let notificationKey = "notification"
    public static let notificationResponseKey = "notification_response"
    public static let deviceTokenKey = "device_token"
    public static let fcmTokenKey = "fcm_token"
    public static let handledKey = "handled"
    public static let processInstanceIDKey = "process_instance_id"

    @discardableResult
    public static func post(
        callback: LifecycleTraceCallback,
        owner: LifecycleTraceOwner,
        kind: LifecycleTraceKind,
        phase: LifecycleTracePhase,
        observations: LifecycleTraceObservation...
    ) -> Bool {
        LifecycleTraceHarness.sharedRecorder?.record(
            callback: callback,
            owner: owner,
            kind: kind,
            phase: phase,
            observations: observations.reduce(LifecycleTraceObservation()) { $0.merging($1) }
        ) ?? false
    }
}
