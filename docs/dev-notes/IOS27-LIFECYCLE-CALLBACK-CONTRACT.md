# iOS 27 native callback producer audit (MBL-2232)

Status: the sample-only native producer implements the canonical v1 wire
contract and fail-closed validation path. It is not production SDK code and is
not L2/L3 evidence without a complete accepted runtime capture.

The authoritative contract is the complete package:

- `IOS27-LIFECYCLE-TRACE-V1.md`;
- `ios27-lifecycle-trace-v1.schema.json`;
- `ios27-lifecycle-capture-manifest-v1.schema.json`;
- `validate_ios27_lifecycle_trace.py` and its checked vectors.

This note records the producer scope honestly. It does not define a second
callback vocabulary or turn source/compile checks into runtime evidence.

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

## Implemented producer boundary

The recorder emits the required manifest/run/stream identity, pristine start
and final end controls, canonical callback/owner/kind/phase tuples, bounded
aliases, FIFO output, and a post-drain receipt. Encoding failure, buffer drop,
alias overflow in L2/L3, unsupported scenario closure, source-patch drift, and
validator drift fail closed. Fixture-owned completion checks remain available
only to focused unit tests and never wrap production completion handlers.

The existing native sample seats cover icon launch, topology-specific background and
foreground transitions, URL and user-activity routing, Live Activity routing,
notification taps, APNs/FCM token registration, and registration failure. The
fixture rejects foreground presentation, notification settings, quick actions,
and background fetch because the sample apps do not own the required result or
completion seats. The disposable source patch instruments four exact Customer.io
source paths only inside a hash-guarded checkout and preserves all delegate,
completion, and routing behavior.

For any later producer, buffer evidence must be physically attainable as well
as monotonic. Each record has `buffer_high_watermark <= sequence`; after a
drop-oldest event, high water equals capacity and the assigned sequence is at
least `buffer_capacity + dropped_records_total`. The checked diagnostic vector
therefore uses capacity 2 for its first drop on assignment 3, rather than
claiming an impossible capacity-64 high water after three assignments.

## Acceptance and handoff boundary

Do not use source or compile output from the Swift producer as MBL-2232 runtime
acceptance evidence. A runtime capture must:

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
may rely on an engine/runtime initialized before recording. Flutter icon-cold
uses the real `flutter.dart-main-entered` Dart application receipt, never a
synthesized `wrapper.app-lifecycle-state`. Its legacy topology is engine ->
plugin -> raw application did-finish -> Flutter application forward -> UIKit
did-finish notification -> UIKit active notification -> Dart main. Its scene
topology is raw application did-finish -> plugin -> Flutter application forward
-> UIKit did-finish notification -> engine -> raw scene will-connect -> Flutter
scene forward -> UIKit active notification -> Dart main. Cold Expo records subscriber
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
Notification origin/class/response and URL/activity/action classifications must
reconcile across the selected handoff records. Background/foreground lifecycle
transitions reconcile by class. Legacy Flutter icon launch preserves inactive
on raw and forwarded application launch; scene-enabled Flutter preserves the
empirically observed background state. Dart main must be captured strictly
after UIKit's active notification. The scene raw/forward pair is exactly once,
preserves its complete safe payload summary, and records
`app_state=pre-application` plus the actual scene state and session role. Expo
remains an explicit progression from an
inactive raw application entry through an inactive native launch forward to an
active lifecycle receipt. Expo additionally
proves its active subscriber and RCT bundle-load seats occurred before that
wrapper receipt. Scene
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
and a preserved occurrence plus delivery/request alias. FCM token registration preserves one
request alias across APNs, Firebase, and Customer.io. Application and scene
lifecycle ingress are mutually exclusive according to the manifest's explicit
`host_topology`; AppDelegate-only is a native control, not an inferred fallback.
The v1 evidence fixture accepts one participating scene and one URL context per
activation, and fails closed before terminal routing if either becomes ambiguous.

Token registration, registration failure, background fetch,
and notification settings are currently canonical native-side single-stream
acceptance scenarios because there is no real Dart/JavaScript app-received seat
for them.

The native and wrapper fixtures use a shared byte-identity lock and closed Swift
schema guard. Actual iOS callback delivery, Xcode 27 runtime behavior, real
APNs/FCM provider behavior, and complete wrapper handoff remain unproven until
their scenario manifests, streams, and post-drain receipts pass the canonical
validator at the claimed L2 or L3 evidence level.
