// This byte-vendored fixture keeps recorder state and serialization together for auditability.
// swiftlint:disable file_length

import Foundation

/// A synchronous line sink. The recorder calls it only from its private serial output queue.
public protocol LifecycleTraceSink: AnyObject {
    @discardableResult
    func write(line: String) -> Bool

    /// Persists the receipt outside the sequenced NDJSON stream.
    func writeReceipt(json: String) -> Bool
}

public extension LifecycleTraceSink {
    func writeReceipt(json: String) -> Bool {
        write(line: LifecycleTraceRecorder.receiptPrefix + json)
    }
}

public final class ConsoleLifecycleTraceSink: LifecycleTraceSink {
    public init() {}

    public func write(line: String) -> Bool {
        print(line)
        return true
    }
}

private struct LifecycleTracePayloadSummary: Codable {
    let flags: [String: Bool]
    let counts: [String: Int]
    let enums: [String: String]
}

private struct LifecycleTraceWireRecord: Encodable {
    let schema = "cio-lifecycle-trace/1"
    let manifestID: String
    let runID: String
    let streamID: String
    let sequence: Int
    let monotonicMilliseconds: Int
    let capturedAt: String
    let processID: Int?
    let integration: LifecycleTraceIntegration
    let runtime: LifecycleTraceRuntime
    let provider: LifecycleTraceProvider
    let scenario: LifecycleTraceScenario
    let evidenceLevel: LifecycleTraceEvidenceLevel
    let owner: LifecycleTraceOwner
    let kind: LifecycleTraceKind
    let callback: LifecycleTraceCallback
    let phase: LifecycleTracePhase
    let mainThread: Bool
    let payloadSummary: LifecycleTracePayloadSummary
    let correlation: [String: String]?
    let completion: LifecycleTraceCompletion?
    let recorder: LifecycleTraceRecorderSnapshot

    enum CodingKeys: String, CodingKey {
        case schema
        case manifestID = "manifest_id"
        case runID = "run_id"
        case streamID = "stream_id"
        case sequence
        case monotonicMilliseconds = "monotonic_ms"
        case capturedAt = "captured_at"
        case processID = "process_id"
        case integration
        case runtime
        case provider
        case scenario
        case evidenceLevel = "evidence_level"
        case owner
        case kind
        case callback
        case phase
        case mainThread = "main_thread"
        case payloadSummary = "payload_summary"
        case correlation
        case completion
        case recorder
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schema, forKey: .schema)
        try container.encode(manifestID, forKey: .manifestID)
        try container.encode(runID, forKey: .runID)
        try container.encode(streamID, forKey: .streamID)
        try container.encode(sequence, forKey: .sequence)
        try container.encode(monotonicMilliseconds, forKey: .monotonicMilliseconds)
        try container.encode(capturedAt, forKey: .capturedAt)
        if let processID {
            try container.encode(processID, forKey: .processID)
        } else {
            try container.encodeNil(forKey: .processID)
        }
        try container.encode(integration, forKey: .integration)
        try container.encode(runtime, forKey: .runtime)
        try container.encode(provider, forKey: .provider)
        try container.encode(scenario, forKey: .scenario)
        try container.encode(evidenceLevel, forKey: .evidenceLevel)
        try container.encode(owner, forKey: .owner)
        try container.encode(kind, forKey: .kind)
        try container.encode(callback, forKey: .callback)
        try container.encode(phase, forKey: .phase)
        try container.encode(mainThread, forKey: .mainThread)
        try container.encode(payloadSummary, forKey: .payloadSummary)
        if let correlation {
            try container.encode(correlation, forKey: .correlation)
        } else {
            try container.encodeNil(forKey: .correlation)
        }
        if let completion {
            try container.encode(completion, forKey: .completion)
        } else {
            try container.encodeNil(forKey: .completion)
        }
        try container.encode(recorder, forKey: .recorder)
    }
}

private struct LifecycleTracePendingRecord {
    let sequence: Int
    let monotonicMilliseconds: Int
    let capturedAt: Date
    let owner: LifecycleTraceOwner
    let kind: LifecycleTraceKind
    let callback: LifecycleTraceCallback
    let phase: LifecycleTracePhase
    let mainThread: Bool
    let payloadSummary: LifecycleTracePayloadSummary
    let correlation: [String: String]?
    let completion: LifecycleTraceCompletion?
    var recorder: LifecycleTraceRecorderSnapshot
}

public struct LifecycleTraceCompletionHandle: Equatable {
    fileprivate let closureAlias: String
    fileprivate let parentSequence: Int
    fileprivate let droppedRecordsAtCreation: Int
}

// swiftlint:disable type_body_length
/// A thread-safe, bounded evidence recorder available before application launch completes.
///
/// Synchronous UIKit and framework callbacks cannot await an actor, so a short `NSLock` protects state and a
/// private serial queue performs ordered sink writes. No host callback or completion runs while the lock is held.
/// State ownership and wire serialization remain co-located to preserve one ordering boundary.
public final class LifecycleTraceRecorder: @unchecked Sendable {
    public static let linePrefix = "CIO-LIFECYCLE-TRACE "
    public static let receiptPrefix = "CIO-LIFECYCLE-RECEIPT "

    private enum State {
        case idle
        case recording
        case ending
        case ended
    }

    private struct FixtureState {
        var observedCallCount = 0
        var hasNotInvokedOutcome = false
    }

    private let context: LifecycleTraceContext
    private let sink: LifecycleTraceSink
    private let bufferCapacity: Int
    private let now: () -> Date
    private let monotonicMilliseconds: () -> Int
    private let stateLock = NSLock()
    private let sinkQueue = DispatchQueue(label: "io.customer.lifecycle-trace.sink")

    private var state = State.idle
    private var nextSequence = 1
    private var lastMonotonicMilliseconds = 0
    private var lastCapturedAt = Date.distantPast
    private var pendingRecords: [LifecycleTracePendingRecord] = []
    private var drainScheduled = false
    private var droppedRecordsTotal = 0
    private var emittedRecords = 0
    private var lastEmittedSequence = 0
    private var bufferHighWatermark = 0
    private var aliasTables: [LifecycleTraceAliasNamespace: [LifecycleTraceCorrelationValue: String]] = [:]
    private var aliasOverflowNamespaces: Set<LifecycleTraceAliasNamespace> = []
    private var fixtureStates: [String: FixtureState] = [:]
    private var negativeFixtureDropFloors: [String: Int] = [:]
    private var endCompletion: ((LifecycleTraceStreamReceipt?) -> Void)?
    private var observedBackgroundSeat = false
    private var participatingSceneIdentity: LifecycleTraceCorrelationValue?
    private var captureFailed = false

    public var scenario: LifecycleTraceScenario { context.scenario }
    public var processInstanceID: String { context.processInstanceID }
    public var hostTopology: LifecycleTraceHostTopology { context.hostTopology }

    // Used only by focused tests to create deterministic overflow. Production code never pauses.
    var isDrainSchedulingPausedForTesting = false

    public init(
        context: LifecycleTraceContext,
        sink: LifecycleTraceSink,
        bufferCapacity: Int = 256,
        now: @escaping () -> Date = Date.init,
        monotonicMilliseconds: @escaping () -> Int = {
            Int(ProcessInfo.processInfo.systemUptime * 1000)
        }
    ) {
        precondition(bufferCapacity >= 2, "trace buffer must preserve start and end control records")
        self.context = context
        self.sink = sink
        self.bufferCapacity = bufferCapacity
        self.now = now
        self.monotonicMilliseconds = monotonicMilliseconds
        for namespace in LifecycleTraceAliasNamespace.allCases {
            aliasTables[namespace] = [:]
        }
    }

    @discardableResult
    public func startScenario(
        observation: LifecycleTraceObservation = LifecycleTraceObservation()
    ) -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard case .idle = state else { return false }

        state = .recording
        _ = enqueueLocked(
            owner: .traceRecorder,
            kind: .traceControl,
            callback: .traceScenarioStart,
            phase: .stateChange,
            observation: observation,
            completion: nil,
            prealiasedCorrelation: nil
        )
        guard !captureFailed else { return false }
        scheduleDrainLocked()
        return true
    }

    @discardableResult
    public func record(
        callback: LifecycleTraceCallback,
        owner: LifecycleTraceOwner,
        kind: LifecycleTraceKind,
        phase: LifecycleTracePhase,
        observations: LifecycleTraceObservation...
    ) -> Bool {
        var observation = observations.reduce(LifecycleTraceObservation()) { $0.merging($1) }
        stateLock.lock()
        defer { stateLock.unlock() }
        guard case .recording = state,
              !captureFailed,
              observation.correlations[.closure] == nil,
              callback != .traceScenarioStart,
              callback != .traceScenarioEnd,
              callback != .fixtureCompletionCreated,
              callback != .fixtureCompletionObserved else {
            return false
        }

        observation.correlations[.occurrence] = .string(context.activationOccurrenceIdentity)
        if observation.counts[.urlContexts, default: 0] > 1 {
            invalidateCaptureLocked()
            return false
        }
        if let sceneIdentity = observation.correlations[.scene] {
            if let participatingSceneIdentity, participatingSceneIdentity != sceneIdentity {
                invalidateCaptureLocked()
                return false
            }
            participatingSceneIdentity = sceneIdentity
        }

        if callback == .sceneDidEnterBackground || callback == .applicationDidEnterBackground ||
            (callback == .swiftUIScenePhaseChange && observation.enums[.appState] == "background") {
            observedBackgroundSeat = true
        }

        _ = enqueueLocked(
            owner: owner,
            kind: kind,
            callback: callback,
            phase: phase,
            observation: observation,
            completion: nil,
            prealiasedCorrelation: nil
        )
        guard !captureFailed else { return false }
        scheduleDrainLocked()
        return true
    }

    /// Invalidates ambiguous evidence without changing the host application's production route.
    public func invalidateCapture() {
        stateLock.lock()
        invalidateCaptureLocked()
        stateLock.unlock()
    }

    /// Records a fixture-owned closure creation. It never accepts a production completion object.
    public func createCompletionFixture(
        closureIdentity: LifecycleTraceCorrelationValue,
        observations: LifecycleTraceObservation...
    ) -> LifecycleTraceCompletionHandle? {
        var observation = observations.reduce(LifecycleTraceObservation()) { $0.merging($1) }
        observation.correlations[.closure] = closureIdentity

        stateLock.lock()
        defer { stateLock.unlock() }
        guard case .recording = state, !captureFailed, context.scenario == .unitFixture else { return nil }

        let pending = enqueueLocked(
            owner: .fixture,
            kind: .fixtureControl,
            callback: .fixtureCompletionCreated,
            phase: .entry,
            observation: observation,
            completion: nil,
            prealiasedCorrelation: nil
        )
        guard !captureFailed else { return nil }
        guard let closureAlias = pending.correlation?[LifecycleTraceAliasNamespace.closure.rawValue] else {
            return nil
        }
        fixtureStates[closureAlias] = FixtureState()
        scheduleDrainLocked()
        return LifecycleTraceCompletionHandle(
            closureAlias: closureAlias,
            parentSequence: pending.sequence,
            droppedRecordsAtCreation: droppedRecordsTotal
        )
    }

    /// Records an outcome for a closure created by `createCompletionFixture`.
    @discardableResult
    public func observeCompletionFixture(
        _ handle: LifecycleTraceCompletionHandle,
        result: LifecycleTraceCompletionResult,
        observations: LifecycleTraceObservation...
    ) -> Bool {
        let observation = observations.reduce(LifecycleTraceObservation()) { $0.merging($1) }
        stateLock.lock()
        defer { stateLock.unlock() }
        guard case .recording = state,
              !captureFailed,
              context.scenario == .unitFixture,
              var fixture = fixtureStates[handle.closureAlias] else {
            return false
        }

        let callIndex: Int?
        switch result {
        case .invoked:
            guard !fixture.hasNotInvokedOutcome else { return false }
            fixture.observedCallCount += 1
            callIndex = fixture.observedCallCount
        case .notInvoked:
            guard fixture.observedCallCount == 0,
                  !fixture.hasNotInvokedOutcome,
                  droppedRecordsTotal == handle.droppedRecordsAtCreation else {
                return false
            }
            fixture.hasNotInvokedOutcome = true
            negativeFixtureDropFloors[handle.closureAlias] = droppedRecordsTotal
            callIndex = nil
        }
        fixtureStates[handle.closureAlias] = fixture

        let completion = LifecycleTraceCompletion(
            closure: handle.closureAlias,
            parentSequence: handle.parentSequence,
            observedCallCount: fixture.observedCallCount,
            callIndex: callIndex,
            result: result
        )
        _ = enqueueLocked(
            owner: .fixture,
            kind: .completionFixture,
            callback: .fixtureCompletionObserved,
            phase: .completion,
            observation: observation,
            completion: completion,
            prealiasedCorrelation: [.closure: handle.closureAlias]
        )
        guard !captureFailed else { return false }
        scheduleDrainLocked()
        return true
    }

    /// Emits the final control record and asynchronously returns the post-drain manifest receipt.
    func endScenarioAndDrain(completion: @escaping (LifecycleTraceStreamReceipt?) -> Void) {
        stateLock.lock()
        guard canEndScenarioLocked() else {
            stateLock.unlock()
            completion(nil)
            return
        }
        beginEndingLocked(completion: completion)
        stateLock.unlock()
    }

    /// Closes only when the caller has just observed a terminal seat valid for this scenario.
    /// A rejected terminal does not invoke `completion`. An accepted close invokes it after drain,
    /// passing `nil` when the receipt cannot be encoded or persisted.
    public func endScenario(
        after terminal: LifecycleTraceTerminal,
        completion: @escaping (LifecycleTraceStreamReceipt?) -> Void
    ) -> Bool {
        stateLock.lock()
        guard canEndScenarioLocked(), terminalIsValidForScenarioLocked(terminal) else {
            stateLock.unlock()
            return false
        }
        beginEndingLocked(completion: completion)
        stateLock.unlock()
        return true
    }

    /// Focused-test helper. This method is never called from application callback code.
    func waitUntilDrainedForTesting() {
        let semaphore = DispatchSemaphore(value: 0)
        sinkQueue.async { semaphore.signal() }
        semaphore.wait()
    }

    // The record's canonical dimensions remain explicit at this single serialization boundary.
    // swiftlint:disable:next function_parameter_count
    private func enqueueLocked(
        owner: LifecycleTraceOwner,
        kind: LifecycleTraceKind,
        callback: LifecycleTraceCallback,
        phase: LifecycleTracePhase,
        observation: LifecycleTraceObservation,
        completion: LifecycleTraceCompletion?,
        prealiasedCorrelation: [LifecycleTraceAliasNamespace: String]?
    ) -> LifecycleTracePendingRecord {
        let sequence = nextSequence
        nextSequence += 1
        let capturedAt = max(now(), lastCapturedAt)
        let monotonic = max(monotonicMilliseconds(), lastMonotonicMilliseconds)
        lastCapturedAt = capturedAt
        lastMonotonicMilliseconds = monotonic
        let aliases = prealiasedCorrelation ?? aliasesLocked(for: observation.correlations)
        var record = LifecycleTracePendingRecord(
            sequence: sequence,
            monotonicMilliseconds: monotonic,
            capturedAt: capturedAt,
            owner: owner,
            kind: kind,
            callback: callback,
            phase: phase,
            mainThread: Thread.isMainThread,
            payloadSummary: LifecycleTracePayloadSummary(
                flags: Dictionary(uniqueKeysWithValues: observation.flags.map { ($0.key.rawValue, $0.value) }),
                counts: Dictionary(uniqueKeysWithValues: observation.counts.map { ($0.key.rawValue, $0.value) }),
                enums: Dictionary(uniqueKeysWithValues: observation.enums.map { ($0.key.rawValue, $0.value) })
            ),
            correlation: aliases.isEmpty ? nil : Dictionary(uniqueKeysWithValues: aliases.map { ($0.key.rawValue, $0.value) }),
            completion: completion,
            recorder: snapshotLocked()
        )

        pendingRecords.append(record)
        let displacedOldestRecord = bufferedRecordCountLocked() > bufferCapacity
        if displacedOldestRecord, !evictOldestBufferedRecordLocked() {
            captureFailed = true
            pendingRecords.removeAll()
            return record
        }
        let observedBufferLoad = max(
            pendingRecords.contains(where: { $0.callback == .traceScenarioStart }) ? 1 : 0,
            bufferedRecordCountLocked()
        )
        bufferHighWatermark = max(bufferHighWatermark, observedBufferLoad)

        record.recorder = snapshotLocked()
        if let index = pendingRecords.firstIndex(where: { $0.sequence == sequence }) {
            pendingRecords[index] = record
        }
        if displacedOldestRecord {
            refreshPendingBufferAccountingLocked()
        }
        return record
    }

    private func bufferedRecordCountLocked() -> Int {
        pendingRecords.reduce(into: 0) { count, pending in
            if pending.callback != .traceScenarioStart {
                count += 1
            }
        }
    }

    private func evictOldestBufferedRecordLocked() -> Bool {
        guard let evictionIndex = pendingRecords.firstIndex(where: {
            $0.callback != .traceScenarioStart
        }) else { return false }
        pendingRecords.remove(at: evictionIndex)
        droppedRecordsTotal += 1
        return true
    }

    private func refreshPendingBufferAccountingLocked() {
        for index in pendingRecords.indices {
            guard pendingRecords[index].callback != .traceScenarioStart else { continue }
            let snapshot = pendingRecords[index].recorder
            pendingRecords[index].recorder = LifecycleTraceRecorderSnapshot(
                droppedRecordsTotal: droppedRecordsTotal,
                aliasCounts: snapshot.aliasCounts,
                aliasOverflow: snapshot.aliasOverflow,
                aliasOverflowNamespaces: snapshot.aliasOverflowNamespaces,
                bufferHighWatermark: bufferHighWatermark,
                bufferCapacity: snapshot.bufferCapacity
            )
        }
    }

    private func aliasesLocked(
        for correlations: [LifecycleTraceAliasNamespace: LifecycleTraceCorrelationValue]
    ) -> [LifecycleTraceAliasNamespace: String] {
        var aliases: [LifecycleTraceAliasNamespace: String] = [:]
        for namespace in LifecycleTraceAliasNamespace.allCases {
            guard let rawValue = correlations[namespace] else { continue }
            var table = aliasTables[namespace] ?? [:]
            if let existing = table[rawValue] {
                aliases[namespace] = existing
            } else if table.count < 256 {
                let alias = "\(namespace.rawValue)-\(table.count + 1)"
                table[rawValue] = alias
                aliasTables[namespace] = table
                aliases[namespace] = alias
            } else {
                aliasOverflowNamespaces.insert(namespace)
            }
        }
        return aliases
    }

    private func snapshotLocked() -> LifecycleTraceRecorderSnapshot {
        let counts = LifecycleTraceAliasCounts(
            occurrence: aliasTables[.occurrence]?.count ?? 0,
            delivery: aliasTables[.delivery]?.count ?? 0,
            request: aliasTables[.request]?.count ?? 0,
            scene: aliasTables[.scene]?.count ?? 0,
            url: aliasTables[.url]?.count ?? 0,
            closure: aliasTables[.closure]?.count ?? 0
        )
        let overflow = LifecycleTraceAliasNamespace.allCases.filter { aliasOverflowNamespaces.contains($0) }
        return LifecycleTraceRecorderSnapshot(
            droppedRecordsTotal: droppedRecordsTotal,
            aliasCounts: counts,
            aliasOverflow: !overflow.isEmpty,
            aliasOverflowNamespaces: overflow,
            bufferHighWatermark: bufferHighWatermark,
            bufferCapacity: bufferCapacity
        )
    }

    private func scheduleDrainLocked() {
        guard !isDrainSchedulingPausedForTesting, !drainScheduled else { return }
        drainScheduled = true
        sinkQueue.async { [weak self] in
            self?.drain()
        }
    }

    private func drain() {
        while true {
            stateLock.lock()
            guard !pendingRecords.isEmpty else {
                drainScheduled = false
                stateLock.unlock()
                return
            }
            let record = pendingRecords.removeFirst()
            stateLock.unlock()

            guard let line = encode(record) else {
                stateLock.lock()
                invalidateCaptureLocked()
                stateLock.unlock()
                return
            }
            let published = sink.write(line: Self.linePrefix + line)

            stateLock.lock()
            guard !captureFailed else {
                stateLock.unlock()
                return
            }
            guard published else {
                invalidateCaptureLocked()
                stateLock.unlock()
                return
            }
            emittedRecords += 1
            lastEmittedSequence = record.sequence
            let isEnd = record.callback == .traceScenarioEnd
            if isEnd {
                state = .ended
                drainScheduled = false
                let receipt = receiptLocked(drainedAt: max(now(), lastCapturedAt))
                let completion = endCompletion
                endCompletion = nil
                let receiptJSON = encode(receipt)
                aliasTables.removeAll()
                fixtureStates.removeAll()
                negativeFixtureDropFloors.removeAll()
                stateLock.unlock()
                guard let receiptJSON, sink.writeReceipt(json: receiptJSON) else {
                    completion?(nil)
                    return
                }
                completion?(receipt)
                return
            }
            stateLock.unlock()
        }
    }

    private func encode(_ pending: LifecycleTracePendingRecord) -> String? {
        let wire = LifecycleTraceWireRecord(
            manifestID: context.manifestID,
            runID: context.runID,
            streamID: context.streamID,
            sequence: pending.sequence,
            monotonicMilliseconds: pending.monotonicMilliseconds,
            capturedAt: Self.timestamp(pending.capturedAt),
            processID: context.processID,
            integration: context.integration,
            runtime: context.runtime,
            provider: context.provider,
            scenario: context.scenario,
            evidenceLevel: context.evidenceLevel,
            owner: pending.owner,
            kind: pending.kind,
            callback: pending.callback,
            phase: pending.phase,
            mainThread: pending.mainThread,
            payloadSummary: pending.payloadSummary,
            correlation: pending.correlation,
            completion: pending.completion,
            recorder: pending.recorder
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(wire) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func encode(_ receipt: LifecycleTraceStreamReceipt) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(receipt) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func canEndScenarioLocked() -> Bool {
        guard case .recording = state, !captureFailed else { return false }
        return negativeFixtureDropFloors.values.allSatisfy { $0 == droppedRecordsTotal }
            && (context.scenario != .unitFixture || !fixtureStates.isEmpty)
            && fixtureStates.values.allSatisfy { $0.observedCallCount > 0 || $0.hasNotInvokedOutcome }
    }

    private func invalidateCaptureLocked() {
        captureFailed = true
        state = .ended
        drainScheduled = false
        pendingRecords.removeAll()
        aliasTables.removeAll()
        fixtureStates.removeAll()
        negativeFixtureDropFloors.removeAll()
        let completion = endCompletion
        endCompletion = nil
        if let completion {
            sinkQueue.async { completion(nil) }
        }
    }

    private func beginEndingLocked(completion: @escaping (LifecycleTraceStreamReceipt?) -> Void) {
        state = .ending
        endCompletion = completion
        _ = enqueueLocked(
            owner: .traceRecorder,
            kind: .traceControl,
            callback: .traceScenarioEnd,
            phase: .stateChange,
            observation: LifecycleTraceObservation(),
            completion: nil,
            prealiasedCorrelation: nil
        )
        if captureFailed {
            state = .ended
            endCompletion = nil
            sinkQueue.async { completion(nil) }
            return
        }
        scheduleDrainLocked()
    }

    private func terminalIsValidForScenarioLocked(_ terminal: LifecycleTraceTerminal) -> Bool {
        switch (context.scenario, terminal) {
        case (.iconColdLaunch, .activeApplication)
            where context.hostTopology == .appDelegateOnly,
             (.iconColdLaunch, .activeScene)
                 where context.hostTopology != .appDelegateOnly,
             (.pushTapWarm, .notificationResponse),
             (.pushTapCold, .notificationResponse),
             (.localNotificationTapWarm, .notificationResponse),
             (.localNotificationTapCold, .notificationResponse),
             (.customURLWarm, .hostURLRoute),
             (.customURLCold, .hostURLRoute),
             (.liveActivityTapWarm, .hostURLRoute),
             (.liveActivityTapCold, .hostURLRoute),
             (.universalLinkWarm, .hostUserActivityRoute),
             (.universalLinkCold, .hostUserActivityRoute),
             (.tokenRegistration, .tokenRegistration),
             (.registrationFailure, .registrationFailure):
            return true
        case (.appBackgroundForeground, .activeApplication)
            where context.hostTopology == .appDelegateOnly,
             (.appBackgroundForeground, .activeScene)
                 where context.hostTopology != .appDelegateOnly:
            return observedBackgroundSeat
        default:
            return false
        }
    }

    private func receiptLocked(drainedAt: Date) -> LifecycleTraceStreamReceipt {
        let snapshot = snapshotLocked()
        return LifecycleTraceStreamReceipt(
            drainedAt: Self.timestamp(drainedAt),
            lastAssignedSequence: nextSequence - 1,
            lastEmittedSequence: lastEmittedSequence,
            emittedRecords: emittedRecords,
            droppedRecordsTotal: snapshot.droppedRecordsTotal,
            bufferHighWatermark: snapshot.bufferHighWatermark,
            bufferCapacity: snapshot.bufferCapacity,
            aliasCounts: snapshot.aliasCounts,
            aliasOverflow: snapshot.aliasOverflow,
            aliasOverflowNamespaces: snapshot.aliasOverflowNamespaces
        )
    }

    private static func timestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }
}

// swiftlint:enable type_body_length
