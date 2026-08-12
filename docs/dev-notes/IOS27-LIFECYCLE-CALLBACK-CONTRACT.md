# iOS 27 native callback producer audit (MBL-2232)

Status: producer draft is not conformant with the canonical v1 capture
contract. It is observer-only sample instrumentation, not production SDK code
and not L2/L3 evidence.

The authoritative contract is the complete package:

- `IOS27-LIFECYCLE-TRACE-V1.md`;
- `ios27-lifecycle-trace-v1.schema.json`;
- `ios27-lifecycle-capture-manifest-v1.schema.json`;
- `validate_ios27_lifecycle_trace.py` and its checked vectors.

This note records the current native producer gap honestly. It does not define a
second callback vocabulary and it makes no schema-conformance, build, runtime,
or evidence claim.

## Canonical callback corrections

The closed schema and relational registry use these exact mappings:

| Callback | Owner | Kind | Phase |
|---|---|---|---|
| `application.did-discard-scene-sessions` | `application-delegate` | `os-callback` | `state-change` |
| `application.did-register-for-remote-notifications` | `application-delegate` | `os-callback` | `entry` |
| `application.did-fail-to-register-for-remote-notifications` | `application-delegate` | `os-callback` | `entry` |
| `swiftui.on-open-url` (iOS 14+) | `swiftui-scene` | `os-callback` | `entry` |
| `swiftui.scene-phase-change` (iOS 14+) | `swiftui-scene` | `os-callback` | `state-change` |
| `host.route-url` | `host` | `host-routing` | `intent` or `result` |
| `customerio.route-deep-link` | `customerio-sdk` | `sdk-routing` | `intent` or `result` |

`host.handle-widget-url` and `cio.deep-link-callback` are not canonical callback
names. Producers must use the closed enum and the validator's exact
integration/runtime/kind/owner/phase matrix. UIApplication, UIScene, SwiftUI,
UN center, APNs/FCM, passive UIKit/RCT, Flutter, Expo, React Native, host, SDK,
wrapper, trace-control, and fixture seats are all defined there.

Runtime `evidence_level` is only `diagnostic`, `L2`, or `L3`. L0 source review
and L1 compile/link results belong in review/build artifacts, never in trace
records. There is no default that turns an unscoped producer record into
canonical evidence.

## Current producer incompatibilities

The frozen draft under `Apps/Common/Source/Diagnostics/` cannot currently emit
a record accepted by canonical v1:

- `LifecycleTraceRecorder.encode` omits required `manifest_id` and `recorder`
  state;
- it has no leading/final `trace-control` records or post-drain manifest stream
  receipt;
- `LifecycleTraceKind` lacks `trace-control` and `fixture-control`;
- `LifecycleTraceOwner` lacks canonical owners including `swiftui-scene`,
  `trace-recorder`, and host/SDK owners;
- `LifecycleTraceEvidenceLevel` emits forbidden `L0`/`L1` values;
- its scenario enum omits local-notification, quick-action,
  registration-failure, and background-fetch scenarios;
- its alias model lacks the `closure` namespace, cumulative counts, overflow
  state, high-water state, and bounded-drop accounting required by v1;
- its completion object lacks `closure`, `parent_sequence`, and
  `observed_call_count`, and no exact fixture-creation record owns the parent;
- the draft `trace_dropped` flag and `dropped_records` payload count are not
  canonical v1 payload fields;
- several sample call sites still use callback/owner/kind/phase combinations
  outside the closed registry.

Consequently, earlier statements that seven synthetic L0 records validated, or
that the producer implemented canonical v1, are withdrawn. No such checked
records are part of this package. The Python vectors are the only current
executable contract examples.

For any later producer, buffer evidence must be physically attainable as well
as monotonic. Each record has `buffer_high_watermark <= sequence`; after a
drop-oldest event, high water equals capacity and the assigned sequence is at
least `buffer_capacity + dropped_records_total`. The checked diagnostic vector
therefore uses capacity 2 for its first drop on assignment 3, rather than
claiming an impossible capacity-64 high water after three assignments.

## Acceptance and handoff boundary

Do not use output from the frozen Swift draft as MBL-2232 acceptance evidence.
Before a later producer-propagation pass can claim conformance, it must:

1. take a validated manifest identity and stable stream metadata from the
   harness;
2. emit one pristine scenario-start and one final scenario-end;
3. emit every mandatory v1 field and only canonical callback seats/payload
   facts;
4. implement cumulative bounded recorder, alias, drop, FIFO, and post-drain
   receipt state;
5. pass the checked Python validator as a complete capture, not merely validate
   isolated JSON objects;
6. build and run the affected sample/test targets under the repository's Xcode
   requirements.

Wrapper work must use the integration derived from its exact manifest
repository/framework provenance. Flutter uses Swift-to-Dart and Expo uses
Swift-to-JavaScript, with shared process-instance proof and scenario-specific
aggregate selectors. Flutter additionally requires equal non-null Swift/Dart
process IDs. Standalone React Native iOS is one native Swift pass-through stream;
the pinned wrapper exposes no automatic JavaScript notification receipt, so a
JavaScript handoff must not be invented.
The executable audited topology is exact. Expo uses `customerio-expo-plugin`
commit `3637028bfa4c5c66752697b346ad826266e6ae03` and version 3.7.1, plus
`customerio-reactnative` commit
`1edc94769359dfd992d6622884561d448d3f8dd9` and version 6.6.2, Expo 57.0.12,
`expo-notifications` 57.0.10, `expo-modules-core` 57.0.10, and React Native
0.86.2. The standalone fixture is the `customerio-reactnative` repository's
checked-in `example` app at that Customer.io commit and version; its lockfile
resolves React Native 0.83.6. Expo's transitive React Native 0.86.2 is not valid
standalone provenance. Arbitrary internally coherent SHAs or versions do not opt
into these source-derived callback seats. A future topology needs a new audited
registry entry, source/signature evidence, mutation coverage, and reconciled
contract version rather than a manifest-only claim.
The selected Swift aggregate member is the integration-specific native
forwarding seat, never the raw OS callback. The complete capture must also
contain the earlier raw ingress with matching safe facts/correlation. Warm runs
may rely on an engine/runtime initialized before recording; cold runs record
Flutter engine creation before plugin registration, or Expo subscriber
registration before app-delegate will-finish forwarding. In a cold Expo run,
the `application.did-finish-launching` entry then precedes both the exact RCT
load notification and Expo did-finish forward, matching the pinned Expo 57
template's call to `startReactNativeModule` from
`didFinishLaunchingWithOptions`. Expo notification delivery additionally uses the pinned
NotificationCenterManager entry and Notifications Emitter event seats; the
pinned Expo subscriber manager has no UIScene forwarding seat. Every raw ingress
with a registered integration mapping maps to exactly one matching native
forward, including unselected alternatives and optional foreground
`application.did-receive-remote-notification` delivery. That optional entry is
allowed at most once per one-stimulus run.
Notification origin/class/response, URL/activity/action classifications, and
lifecycle app state must reconcile across the selected handoff records. Scene
aliases are stream-local and cannot be used as cross-stream identity. Cold
scene connection-options seats must record only their scenario's defining
URL/activity/action/notification safe facts,
and foreground notification evidence includes the exact host presentation
result. URL and Live Activity evidence also needs one terminal host route pair;
Live Activity needs the enclosed Customer.io deep-link pair. Route intents
carry `has_redirect` classification but no terminal outcome. Route results
repeat that classification and add consistent `handled`/`result` facts; a
Customer.io redirect is exactly `true`/`true`/`redirect`, and its handled
outcome agrees with the terminal host outcome.
Remote push-tap additionally requires `action_class=default` and one later
`customerio.handle-notification-response` result with Customer.io classification
and a preserved delivery/request alias. FCM token registration preserves one
request alias across APNs, Firebase, and Customer.io. Application and scene
lifecycle ingress may both occur, but each must have its own state-qualified
Flutter forward.

Token registration, registration failure, background fetch,
and notification settings are currently canonical native-side single-stream
acceptance scenarios because there is no real Dart/JavaScript app-received seat
for them.

Until that propagation and runtime validation are performed, the only honest
claim is that the canonical schemas, documentation, validator, and vectors
define the intended contract. Actual iOS delivery, sample buildability, Xcode
27 behavior, provider behavior, and wrapper handoff remain unproven.

The canonical package currently exists only in this iOS MBL-2232 worktree.
No byte-identity assertion or Swift schema guard exists for sibling
repositories. Any copied wrapper contract or current producer fixture is stale
and non-conforming until the later propagation pass.
