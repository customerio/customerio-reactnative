# iOS lifecycle trace contract v1

This contract is the MBL-2232 fixture boundary shared by native iOS, Flutter,
Expo, and React Native. A captured line is exactly the ASCII prefix
`CIO-LIFECYCLE-TRACE ` followed by one compact JSON object that validates
against `ios27-lifecycle-trace-v1.schema.json`.

Every capture has exactly one manifest that validates against
`ios27-lifecycle-capture-manifest-v1.schema.json`. Records and the manifest
share lowercase RFC 4122 UUIDs in `manifest_id` and `run_id`. A UUID, commit,
source snapshot, toolchain, SDK, target, dependency, provider, stimulus, or
timestamp must never be guessed after capture.

## Evidence boundary

- **diagnostic:** unscoped traces, schema vectors, and completion fixtures.
  They prove no OS callback behavior.
- **L2, simulator runtime:** a complete, zero-drop capture from the manifest's
  simulator, OS build, architecture, SDK, built target, dependencies, provider,
  and single scenario.
- **L3, physical-device runtime:** a complete, zero-drop capture from the
  stated physical-device model and a real provider or backend path.

L0 source inspection and L1 compile/link results belong in build logs, not
runtime trace records. Runtime `evidence_level` is limited to `diagnostic`,
`L2`, and `L3`. `scenario` and `evidence_level` are harness inputs and must not
be inferred from a callback or payload. `unscoped` and `unit-fixture` cannot be
acceptance evidence.

Every L2/L3 stream must contain at least one non-control runtime observation.
A start/end-only file is not callback evidence. A missing, truncated, dropped,
or unflushed tail can never prove that a callback did not occur.

## Reproducible manifest

The harness writes the final manifest only after every declared recorder has
logically drained. It records:

- `manifest_id`, the shared harness `run_id`, and run start/end/creation times;
- explicit `host_topology`: `app-delegate-only`, `ui-scene`, or
  `swiftui-lifecycle`; it is never inferred from observed callbacks;
- exact lowercase production repository commits and whether each production
  checkout was dirty;
- for a dirty production repository, SHA-256 hashes of both the source tree
  snapshot and diff snapshot used for the build;
- when a fixture checkout differs from the audited production repository,
  separate `fixture_source` provenance with its exact commit, actual checkout
  dirty state, and required snapshot hashes when dirty;
- Xcode version/build, Swift, Flutter, Dart, Node, and Expo CLI versions;
- iOS SDK name/version/build, scheme, target, configuration, product kind, and
  deployment target;
- target kind, model, architecture, OS name/version/build, never a UDID;
- Customer.io SDK/wrapper/runtime versions and the peer/plugin versions that
  influence forwarding behavior;
- provider source/environment/SDK and the harness-observed receipt result/time;
- exactly one stimulus with its scenario, source, and initiation time;
- every stream's stable metadata, harness-issued `process_instance_id`, and
  post-drain logical receipt;
- exact-count cross-stream assertions.

Free provenance labels use a restricted grammar that excludes URL, query,
fragment, and email punctuation. Manifests must not smuggle URLs, email
addresses, or payload values into
scheme, target, model, build, or version fields. UUID/UDID/device-identifier
substrings are forbidden throughout human labels, toolchain versions/builds,
SDK builds, target OS builds, framework versions, and provider SDK versions.
Repository commits and explicit source snapshot hashes remain the only hash
provenance fields.

Framework names have fixed roles. Relevant peers include
`firebase-ios-sdk-messaging`, `flutterfire-firebase-messaging`,
`flutter-local-notifications`, `quick-actions-ios`, `expo-notifications`,
`expo-modules-core`, `customerio-reactnative`, `react-native`, and
`react-native-push-notification`. Expo captures include both the Customer.io
React Native bridge and React Native runtime because Expo uses them internally.
A provider API client is recorded as `apns-provider-sdk` or
`fcm-provider-sdk` with role `provider-sdk`.

A Customer.io framework commit must equal the owning repository commit. In
particular, `customerio-messaging-push` uses the `customerio-ios` repository
commit. Customer.io iOS modules declared at that same commit also use one
coherent package version; a module cannot claim an unrelated version.
Flutter's runtime framework version must equal the Flutter toolchain version.
A dirty repository cannot omit its source snapshot hashes, and a clean
repository must use `source_snapshot=null`.
`repositories` and their owning framework commits identify the production code
whose callback topology is being exercised. `fixture_source` identifies the
harness checkout that generated and instrumented that topology; it does not own
a framework and is never substituted for production repository provenance.
Every audited production repository in a wrapper topology must be clean;
arbitrary local changes cannot retain an audited callback-topology claim.
Expo L2/L3 captures require `fixture_source.name=customerio-expo-plugin` so a
clean committed fixture branch remains reproducible without falsely attributing
its fixture-only commit to the installed Expo plugin. Its `dirty` flag always
describes the actual fixture checkout status, not whether its commit differs
from the audited production commit.

Every Swift stream requires `swift_version`, every Dart stream requires Flutter
and Dart versions, and every JavaScript stream requires Node. Integration-level
requirements add the matching runtime, wrapper, plugin, and CLI peers. The
integration is derived from repository/framework provenance and must match every
stream declaration. A manifest cannot retain Customer.io Flutter, Expo, or
React Native provenance while relabeling its streams `native-ios`, and it cannot
mix wrapper provenance families. For L2/L3, Xcode/SDK/OS builds, toolchains, and
framework versions are exact non-placeholder values; `unknown`, `snapshot`,
`latest`, generic device models, and incomplete runtime metadata are invalid. The
target OS cannot be older than the build deployment target. Safe labels must be
human-readable and cannot contain a UDID/UUID even when they otherwise match the
restricted character grammar. `target.model` additionally uses an
iPhone/iPad/iPod device-model grammar, so a serial-shaped value such as
`C02ZQ0ABCDEF` is invalid. iPhone/iPod models require `os_name=iOS`, while iPad
models require `os_name=iPadOS`. L2/L3 captures must build an application target;
unit-test and UI-test products cannot stand in for application lifecycle
evidence.

## One stimulus and provider compatibility

`stimulus` is one object, never a list. A second tap, launch, push, quick action,
or injection requires a new `run_id`. Native and wrapper streams for the same
stimulus share that `run_id` and a harness-issued `process_instance_id`, but
retain independent `stream_id` and sequence. Flutter Swift and Dart declarations
also require the same non-null OS `process_id`. Expo JavaScript may report a null
OS process ID only with the shared process-instance proof; a reported ID must
match Swift. Standalone React Native on iOS is modeled as one native Swift
pass-through stream. There is no automatic Customer.io JavaScript
notification-receipt seat to aggregate.

Every L2/L3 non-control seat also carries one safe `correlation.occurrence`
alias. The harness mints its opaque process-local identity at first ingress and
forwards it through the graph. A terminal, opened metric, or host route may be
committed only once for that occurrence. A later activation with an identical
payload is a new run and a new occurrence; permanent URL/delivery deduplication
and time-window heuristics are not evidence of this contract.

Provider and stimulus provenance is scenario-aware:

- remote push foreground/tap uses APN or FCM. Simulator injection is
  `simulator-control` + `simulator` + `injected`; a real provider path is
  `provider-api|provider-console` + `sandbox|production` + `accepted`;
- every remote acceptance run has a non-unknown receipt and receipt timestamp;
- L3 remote evidence requires a physical device and a real provider path;
- `provider-api` requires the matching `apns-provider-sdk` or
  `fcm-provider-sdk` provenance and framework peer. `provider-console` has no
  provider SDK, because the harness did not invoke an API client;
- local-notification scenarios use provider `local`, a local/system scheduler,
  environment `local`, result `scheduled`, a receipt timestamp, and no provider
  API SDK;
- registration success/failure uses APN/FCM with `system-registration` and the
  matching `registered` or `failed` result, also without a provider API SDK;
- L3 registration uses a physical device and `sandbox|production`; a
  `simulator` registration environment is L2-only and cannot prove a real path;
- URL, quick-action, lifecycle, settings, background-fetch, and Live Activity
  tap scenarios use provider `none` and their scenario-specific stimulus seat.
- diagnostic `unit-fixture` also requires provider `none`, not-applicable
  provenance, and `provider_sdk=null`.

The validator rejects incompatible combinations before examining callback
counts.

L2/L3 records also enforce scenario-bound external ingress. URL, user-activity,
quick-action, notification delivery/response, cold launch, and background-fetch
entry/forwarding seats and the matching `wrapper.app-received-url`,
`wrapper.app-received-user-activity`, `wrapper.app-received-notification`, and
`wrapper.app-received-quick-action` seats can occur only in their compatible
scenario. Ordinary
application/scene state transitions and existing host/SDK routing remain
permitted side effects and do not create a second stimulus.

`fcm.registration-token-refreshed` is an FCM SDK token observation and always
requires the declared `firebase-ios-sdk-messaging` peer, even if the surrounding
manifest provider is APN. It is not by itself end-to-end registration evidence.
APN token-registration acceptance requires the APNs application-delegate seat
followed by `customerio.register-device-token` at phase `result`; FCM acceptance
requires the ordered APNs application-delegate seat, FCM token-refresh seat,
and Customer.io registration result seat, each exactly once. The applicable
single request alias is preserved from APNs through FCM and into Customer.io,
and provider-token presence/count facts are preserved along the applicable
chain. Matching only FCM to Customer.io is insufficient. A routing intent alone
is not an end-to-end registration result.

## Time model

`run_started_at <= stimulus.initiated_at <= run_ended_at <= created_at`.
Harness-observed provider receipts cannot predate the stimulus or exceed the run
end. Non-control runtime observations, `trace.scenario-end`, and the post-drain
receipt occur at or after the stimulus and any applicable provider receipt.
For a cold-start scenario the process-local `trace.scenario-start` also occurs
at or after that barrier; a process that does not exist yet cannot record a
pre-stimulus start. Warm-run start markers may precede the stimulus so the
harness can arm recorders. Record `captured_at` values are nondecreasing within
a stream and fall inside run bounds. Each stream receipt's `drained_at` is no
earlier than its last captured record and no later than the run end.

These are harness-wall-clock checks, not distributed-clock causality. Provider
timestamps are recorded when the harness observes a receipt, not copied from a
remote provider clock. Cross-stream ordering uses monotonic sequence within each
stream and exact aggregate counts, never wall-clock tie breaking.

## Privacy and bounded aliases

Records and manifests never contain raw payloads, tokens, token prefixes, token
hashes/digests, URL hosts/paths, query names/values, fragments, delivery or
request identifiers, scene/device/customer identifiers, or localized error
descriptions. `commit_sha` and source snapshot hashes are source provenance,
not payload digests.

Within-stream correlation uses a first-seen ordinal alias. The `occurrence`,
`delivery`, `request`, `scene`, `url`, and `closure` namespaces each cap at 256 aliases.
Alias maps are in-memory, scoped to one stream and scenario, and reset only
after the post-drain receipt is generated. They are never persisted or logged.
Ordinal aliases are stream-local. Equal text such as `scene-1` in two streams
does not establish shared scene identity and is never compared across streams;
v1 has no cross-stream scene-identity claim.

Every record snapshots cumulative per-namespace `alias_counts`, cumulative
`alias_overflow_namespaces`, and the summary `alias_overflow` boolean. A
namespace may claim overflow only after its count has reached 256. An overflow
namespace never disappears. The 257th raw value is not assigned an alias.

For zero-drop L2/L3, emitted first-seen aliases are exactly contiguous from 1 to
the final count. Diagnostic data may omit an allocated ordinal only when a
record drop accounts for that uncertainty; per namespace, missing allocated
ordinals cannot outnumber dropped records. Any drop or overflow invalidates
L2/L3. Because the recorder's policy is drop-oldest-on-full, any claimed drop
also requires cumulative `buffer_high_watermark == buffer_capacity`; a drop
from a buffer whose high water never reached capacity is impossible evidence.
The high-water snapshot must also be physically attainable: at every emitted
record `buffer_high_watermark <= sequence`, because sequence is the cumulative
assigned-record count. Once drops are nonzero, `sequence` must be at least
`buffer_capacity + dropped_records_total`. Thus a capacity-64 recorder cannot
claim high water 64 or its first drop after only three assignments. The checked
diagnostic drop vector deliberately uses capacity 2, reaches high water 2, and
records its first drop on assignment 3.
A later emitted reference to an alias whose allocating record was dropped is
valid when the earlier cumulative allocation count and drop uncertainty account
for it; it is not treated as a new out-of-order allocation.

Aliases have no meaning outside a stream. Cross-stream comparisons use the
shared run, single stimulus, and exact aggregate selectors.

## Observer-only recorder

1. A recorder never installs a delegate, subscriber, swizzle, or callback seat
   merely to observe an event. It instruments an existing seat or an existing
   passive notification.
2. It never routes, consumes, awaits, deduplicates, retains, wraps, or invokes a
   production completion handler.
3. Existing host/SDK routing is recorded as `intent` before the side effect and
   `result` after it. The tracer does not make the decision.
4. Sequence means recorder enqueue/linearization order, not unknowable OS
   callback-entry order.
5. A short native critical section assigns sequence/aliases, snapshots recorder
   state, and enqueues an immutable safe record. JSON encoding and output run on
   a dedicated serial sink. Callback threads perform no disk or console I/O.
6. The buffer is bounded and never blocks a lifecycle callback. It drops the
   oldest un-emitted record and increments cumulative drop state.

The recorder must preserve iOS 13 behavior. On iOS 13,
`presentation_alert` represents `.alert`; iOS 14-only `.banner` and `.list`
remain false unless guarded by availability and actually selected.

## FIFO, scenario end, and post-drain receipt

Each stream has exactly one leading `trace.scenario-start` at sequence 1 and
exactly one final `trace.scenario-end`; duplicate or mid-stream control markers
are invalid. The start has zero drops and zero alias counts. Output sequence is
strictly increasing and unique. The start also has `correlation=null`, no alias
overflow, empty overflow namespaces, and `buffer_high_watermark=1`; it cannot
inherit state from an older scenario.
`monotonic_ms`, cumulative drops, alias counts, overflow namespaces, and buffer
high-water state never decrease. Buffer capacity is stable.

A diagnostic sequence gap is valid only when its size exactly equals the
increase in cumulative drops. L2/L3 allow no gap. The final sequenced record is
`trace.scenario-end`. It declares logical scenario closure but does not itself
claim the serial sink has drained.

After the sink drains through that end record, the harness/recorder creates the
manifest stream receipt. The receipt repeats the last assigned/emitted sequence,
emitted/drop totals, final high water/capacity, alias counts, and overflow
namespaces. The validator reconciles it with the final recorder snapshot and
requires `emitted_records + dropped_records_total == last_assigned_sequence`.
Because the receipt is outside the sequenced stream, it does not count itself or
create a recursive flush record.

This proves logical FIFO output and recorder accounting through the end marker.
It does not prove filesystem `fsync`, console subsystem durability, log upload,
or crash-safe persistence. Missing tail data therefore cannot prove callback
absence.

## Completion fixture

Completion ownership is tested only in a diagnostic `unit-fixture`. A
`fixture-control` record with owner `fixture` and callback
`fixture.completion-created` carries `correlation.closure`. Each later
`completion-fixture` record has owner `fixture`, callback
`fixture.completion-observed`, the same closure, and a `parent_sequence` that
points to that exact creation record. The parent is stable for the closure's
entire outcome series. Each creation closure is unique and reconciles to one
nonempty outcome series; absence of both sides is not evidence and a creation
without an outcome is invalid.

- nested `completion.owner` is always `fixture`;
- `result=invoked` requires cumulative, ordinal `call_index` and
  `observed_call_count`;
- `result=not-invoked` requires count zero and forbids `call_index`;
- a negative `not-invoked` result requires no drop from its closure-creation
  record through final scenario closeout, because any such drop destroys the
  absence claim;
- closure aliases are forbidden on non-fixture runtime records.

The recorder never observes or owns production completion closures.

## Callback and seat registry

The schema callback enum is closed, and the validator assigns every callback an
exact integration/runtime/kind/owner/phase matrix. This distinguishes OS seats
from framework forwarding seats:

- UIApplicationDelegate, UISceneDelegate, SwiftUI scene, UN center, APNs, and
  FCM callbacks;
- passive UIApplication launch/state/terminate and UIScene notifications;
- exact Expo-observed React Native legacy notifications and bridgeless
  `RCTInstanceDidLoadBundle` observation;
- Flutter implicit engine creation, plugin registration, and forwarded
  application/scene/UN/APNs/URL/user-activity/quick-action seats;
- Expo app-delegate will/did-finish forwarding, subscriber registration and
  UIApplication forwarding, NotificationCenterManager UN entry, Notifications
  Emitter event results, and cold-start last-response pull;
- separate Flutter Dart and Expo JavaScript `wrapper.app-received-*`
  observations; standalone React Native adds no invented JavaScript receipt;
- host and Customer.io routing seats, trace control, and fixtures.

The Expo registry is tied to the generated Expo 57 fixture at
`customerio-expo-plugin` commit
`3637028bfa4c5c66752697b346ad826266e6ae03` (`customerio-expo-plugin` 3.7.1,
`expo` 57.0.12, `expo-notifications` 57.0.10, `expo-modules-core` 57.0.10,
`customerio-reactnative` 6.6.2, and React Native 0.86.2). It also pins
`customerio-reactnative` commit
`1edc94769359dfd992d6622884561d448d3f8dd9`. Standalone React Native uses that
same Customer.io React Native commit, `customerio-reactnative` 6.6.2, and the
React Native 0.83.6 version resolved by the repository's checked-in `example`
app lockfile.
Expo's transitive React Native 0.86.2 is not valid standalone provenance.
These are executable entries in `AUDITED_WRAPPER_TOPOLOGIES`, not illustrative
versions. An internally coherent arbitrary SHA or version such as 99.0.0 cannot
opt into these callback signatures. A future wrapper topology requires a new
source/signature audit, a checked registry entry with mutation coverage, and
reconciled contract documentation; after v1 publication, that is a new contract
version rather than a manifest self-assertion.
`NotificationCenterManager.userNotificationCenter(_:willPresent:withCompletionHandler:)`
and `...didReceive:withCompletionHandler:` are manager entry seats;
`EmitterModule.willPresent(_:)` and `didReceive(_:)` produce the corresponding
event-result seats after `OnCreate` registers the emitter delegate. Expo
UIApplication subscriber forwarding uses owner `expo-subscriber`, never
`application-delegate`, while app-delegate forwarding uses `expo-framework` and
notification manager/emitter records use `expo-notifications`. The pinned Expo
subscriber manager does not forward UIScene callbacks, so v1 defines no Expo
scene-forwarded seat. Expo Swift may observe passive RCT notifications with
owner `rct-notification`. The last-response pull is distinct from callback
delivery, is valid only for a cold notification-tap scenario, and cannot replace
a warm callback. In the pinned Customer.io React Native iOS source,
`onMessageReceived` performs no iOS processing and
`trackNotificationResponseReceived` is an explicit JavaScript-to-native call
at `customerio-reactnative` commit
`1edc94769359dfd992d6622884561d448d3f8dd9`,
not an automatic app receipt; therefore standalone React Native remains native
pass-through evidence.
The callback availability matrix requires iOS 14 or newer for
`swiftui.on-open-url` and `swiftui.scene-phase-change`; neither can be used as an
iOS 13.7 observation.

`host.present-notification` is result-only and records exact presentation
flags immediately before the existing host owner invokes its completion. Every
foreground remote or local notification acceptance run requires exactly one
such result in addition to exactly one UN-center will-present callback.
`host.background-fetch-completion-result` is also result-only. The OS
`application.perform-background-fetch` callback remains entry-only, so a
result trace cannot masquerade as OS callback delivery.

## Payload facts

The validator requires callback-specific safe summaries:

- URL callbacks require `has_url`, URL class/scheme, and path/query counts;
- user-activity and quick-action callbacks require their presence/count/class;
- APNs/FCM token callbacks require token presence and byte/character counts;
- registration failures require registration/failure enums;
- warm/cold lifecycle observations require `app_state`;
- notification paths require exact remote/local origin,
  Customer.io/non-Customer.io class, and `delegate_peer`;
- remote push-tap response seats require `action_class=default`; dismiss and
  custom actions are not notification-tap acceptance;
- L2/L3 notification evidence cannot use an unknown, `none`, or unattested
  `framework-other` delegate peer;
- presentation and background-fetch result seats require exact flags/results.

For a cold custom URL, Universal Link, quick action, or Live Activity URL, a
`scene.will-connect` defining seat represents `connectionOptions` and must carry
the corresponding URL, user-activity, or shortcut safe facts in addition to its
scene facts. `swiftui.on-open-url` may define a Universal Link using classified
HTTP(S) URL facts, with a matching wrapper URL handoff.
The scenario-defining `connectionOptions` family is exclusive: a custom-URL
run cannot also claim a shortcut or notification, and the analogous unrelated
facts are forbidden for every other cold scenario. `scene.will-connect` also
records launch-compatible `app_state`.

Presence facts and their details are logically coupled. A true presence flag
cannot use a corresponding `none` enum or zero token/activity length, while a
false presence flag cannot carry a non-`none` class or nonzero count. A
notification response implies a notification. Custom URL, universal-link, and
Live Activity scenarios require their matching safe URL/activity class.
`customerio.route-deep-link` is a URL callback and cannot bypass these facts.
Foreground/will-present seats cannot claim a notification response.
Presentation facts are exclusive to `host.present-notification`; on a target
below iOS 14, banner/list flags must be false on every seat. `presentation_class`
is `visible` exactly when at least one alert/badge/sound/banner/list flag is true,
and `suppressed` exactly when all are false; `presentation_options` equals the
number of true flags. Remote-delivery callback names always require
`notification_origin=remote` and cannot satisfy a local-notification handoff. The
`customerio.register-device-token` seat is provider-aware: APN uses device-token
presence/byte count and FCM uses FCM-token presence/character count.

`delegate_peer` distinguishes `host`, `customerio-messaging-push`,
`expo-notifications`, `flutter-local-notifications`,
`react-native-push-notification`, and diagnostic-only `framework-other`. Every
named framework peer must match an exact manifest framework name and role.

## Scenario causality and terminal routing

Within the Swift stream, sequence proves these scenario-specific relations:

- `notification-center.will-present` precedes exactly one
  `host.present-notification` result with the same delivery/request alias and
  notification origin/class/response facts;
- `application.perform-background-fetch` precedes the matching host completion
  result with the same request alias;
- a remote notification response precedes exactly one
  `customerio.handle-notification-response` result with
  `notification_class=customerio`, `action_class=default`, `result=handled`,
  matching safe facts, and the same delivery/request alias;
- a foreground run may contain one secondary
  `application.did-receive-remote-notification` entry; if present it occurs at
  most once and maps to exactly one fact/correlation-matched Flutter or Expo
  application forward. Duplicate, contradictory, or unforwarded secondary
  delivery is invalid;
- APNs registration precedes Customer.io registration, and an FCM run inserts
  its Firebase token-refresh observation between those seats while preserving
  one request alias across all three;
- every background-defining application/scene observation precedes every
  foreground-defining observation;
- a cold application launch precedes the cold notification, URL, activity, or
  quick-action ingress.

Callback-to-state rules are exact. For example, did-enter-background is
`background`, did-become-active is `active`, will-enter-foreground is
`background|inactive`, and launch/will-connect is
`pre-application|inactive`. The same rules apply to passive UIKit and native
forwarding seats; wrapper/Flutter lifecycle state must be concrete for L2/L3.

Custom URL and Live Activity routing starts at exactly one raw URL ingress. It
then has exactly one `host.route-url` intent and one later terminal result.
Custom URL may have zero or one Customer.io deep-link intent/result pair; Live
Activity requires exactly one pair between the host intent and result. Every
seat preserves the classified URL facts and one non-null stream-local `url`
alias. Duplicate, omitted, reordered, or contradictory route seats invalidate
acceptance. Route intents carry classification plus `has_redirect` and never
claim `handled` or `result`. Route results repeat `has_redirect` and add
`handled` plus the terminal `result`: host results use `handled` or `unhandled`
consistently with the boolean, while a redirecting Customer.io result uses
`has_redirect=true`, `handled=true`, and `result=redirect`. Intent/result pairs
must agree on redirect classification, the host and Customer.io intents must
agree when the Customer.io pair exists, and the Customer.io terminal handled
outcome must agree with the host terminal outcome. This keeps intent
classification distinct from terminal behavior while rejecting contradictory
route evidence. Universal-link activity handoff remains activity-to-activity even
when the native activity object also exposes incidental URL facts; the chosen
callback family, not `has_url` alone, selects the compared safe-fact family.

## Exact aggregate assertions

Each aggregate assertion has `relation=equal-exact-count`,
`expected_count=1`, and at least two selectors. Trace-control and fixture
callbacks cannot be selected. Every selected stream count must equal one.
Equality alone is insufficient: 0==0 and 2==2 both fail. Multi-stream L2/L3
requires at least one scenario-specific native/wrapper handoff assertion.
The selected Swift and Dart/JavaScript streams must belong to the same supported
wrapper topology: Flutter Swift to Flutter Dart or Expo Swift to Expo
JavaScript. Except for the four native-only scenarios below, a Flutter or Expo
L2/L3 wrapper capture always has exactly those two runtime seats; a single Swift
stream cannot claim Flutter/Expo wrapper acceptance. Standalone React Native is
the explicit exception: it is a native Swift pass-through capture because the
pinned iOS wrapper has no automatic JavaScript receipt. The two selected
records also reconcile notification origin/class/response or the applicable
URL, user-activity, quick-action, or lifecycle transition safe facts. Scene
aliases remain stream-local and are deliberately excluded from cross-stream
handoff comparison. Icon launch handoff is narrowed to the defining
`application.did-finish-launching` seat. Flutter uses the real Dart application
receipt `flutter.dart-main-entered`, with owner `flutter-dart`, runtime `dart`,
kind `app-received`, and phase `entry`; `wrapper.app-lifecycle-state` remains
reserved for genuine lifecycle callbacks. Legacy Flutter requires inactive raw
and forwarded application launch seats. Scene-enabled Flutter requires those
two seats to preserve the empirically observed background state. In both
topologies, Dart main must be captured strictly after UIKit's active
notification. The scene raw/forward pair is exactly once, preserves the full
safe payload summary, and records `app_state=pre-application` with the actual
scene state and session role. Expo retains the inactive native launch to active wrapper
lifecycle progression. For Expo,
one active application seat and one active subscriber forward must occur after
the did-finish forward, and both that active forward and the RCT bundle-load
seat must be captured before the wrapper receipt. Unrelated initialization callbacks cannot substitute
for this progression. Equal counts with contradictory
payload classifications are not a handoff. A multi-stream L2/L3 manifest cannot
mix unrelated integrations outside that shared topology.

The Swift selector in a wrapper aggregate is the integration-specific
forwarding seat, never the raw OS callback. The validator separately requires
the raw ingress, then proves raw ingress -> later native forward using matching
safe facts and the applicable stream-local alias, then reconciles that forward
with the Dart/JavaScript receipt. A warm scenario assumes the engine/bridge was
initialized before the recorder armed and does not invent historical bootstrap
records. A cold run instead requires in-process bootstrap seats. Flutter
icon-cold is topology-specific: legacy requires engine -> plugin -> raw
application did-finish -> Flutter application forward -> UIKit did-finish
notification -> UIKit active notification -> Dart main; scene-enabled requires
raw application did-finish -> plugin -> Flutter application forward -> UIKit
did-finish notification -> engine -> raw scene will-connect -> Flutter scene
forward -> UIKit active notification -> Dart main. Expo requires
subscriber registration before app-delegate will-finish forwarding, followed
by the `application.did-finish-launching` entry. That application entry must
precede both the exact RCT load notification and Expo's did-finish forward,
matching the pinned Expo 57 template where `startReactNativeModule` is invoked
inside `didFinishLaunchingWithOptions`. RCT load notification versus the
did-finish forward is not otherwise ordered because bundle loading may complete
asynchronously. A cold Expo notification run also records
Notifications Emitter creation before its event result. There is no fabricated
React Native bridge/instance acceptance chain.

Exactly-once applies to the whole ingress mapping, not only the two aggregate
selectors. Every raw ingress must have one and only one fact/correlation-matched
registered integration forward, including scenario-compatible secondary ingress
that is not selected by an aggregate. Any unselected alternate valid forward, duplicate terminal
forward, or alternate wrapper receipt invalidates the run even when the chosen
aggregate members still each count to one.

Independently of aggregates, the validator's acceptance registry requires each
scenario-defining OS seat exactly once for the one stimulus. For example,
push-tap acceptance requires exactly one
`notification-center.did-receive-response` and one later Customer.io handled
default-action terminal; an arbitrary active-state callback, dismiss action, or
custom action cannot stand in for it. Duplicating a defining or alternate
forwarding seat invalidates both single- and multi-stream runs. Cold scenarios
additionally require the launch seat. Cold URL/activity/action delivery may use
a `scene.will-connect`
connection-options defining seat, and SwiftUI onOpenURL is an allowed Universal
Link defining seat on iOS 14 or newer. Background fetch requires both entry and
host completion-result seats,
and the remaining scenarios have equivalent notification, URL, user-activity,
quick-action, registration, settings, or state-transition requirements. A
future negative/absence assertion must use a separate schema type; zero is
deliberately not overloaded here.

Application, UIScene, and SwiftUI activation seats are topology alternatives,
not competing owners. `app-delegate-only` accepts application URL, activity,
quick-action, and lifecycle ingress and rejects scene/SwiftUI seats. `ui-scene`
accepts the corresponding scene ingress and rejects application UI activation
and SwiftUI seats. `swiftui-lifecycle` accepts SwiftUI URL/scene-phase ingress
and rejects UIKit scene and application UI activation seats. AppDelegate still
owns launch, APNs registration/failure, and UNUserNotificationCenter callbacks
and completion composition in every topology. When a UIScene connects,
`application.did-finish-launching` must precede `scene.will-connect`.

The v1 fixture permits exactly one participating scene per capture. Every scene
seat carries the same `correlation.scene`; a second distinct scene or multiple
URL contexts invalidate the capture before terminal/open/routing evidence can
be claimed. Production coordination may scope independent windows separately,
but one window must never suppress another.

`app-background-foreground` requires one topology-specific background and one
topology-specific foreground transition. For a SwiftUI lifecycle, the
state-qualified seats are exactly one `swiftui.scene-phase-change` with
`app_state=background` and exactly one with `app_state=active`; intermediate
`app_state=inactive` phase changes are permitted but do not satisfy either
required transition.
Wrapper acceptance for this scenario uses two assertions, one for background
and one for foreground. Each member has an `app_state` qualifier so two honest
Dart/JavaScript lifecycle records are counted independently instead of failing
an undifferentiated exact-count selector. Cross-stream comparison uses the
derived transition class; stream-local scene aliases remain outside the claim.
For Flutter, each raw topology-specific transition must map to its own
state-qualified native forwarding seat.
`token-registration`, `registration-failure`, `background-fetch`, and
`notification-settings` are native-side single-stream acceptance topologies in
v1 because no canonical Dart/JavaScript app-received callback exists for them.

## Validation

The validator performs Draft 2020-12 schema validation with RFC 3339 format
assertion, followed by manifest, cross-record, cross-stream, payload, and
receipt checks. At startup it verifies that `jsonschema` actually provides the
`date-time` format checker; the relational parser also rejects date-only or
offset-naive values as a `ContractError`. Schema timestamps use the same
canonical uppercase `T`/`Z` pattern as the parser. It has no implicit network or
installation behavior. Install its explicit dependency, then run tests
naturally from the repository root:

```sh
python3 -m pip install 'jsonschema[format]>=4.18,<5'
python3 docs/dev-notes/test_validate_ios27_lifecycle_trace.py
```

Validate a capture with:

```sh
python3 docs/dev-notes/validate_ios27_lifecycle_trace.py \
  path/to/manifest.json path/to/native.ndjson path/to/wrapper.ndjson
```

This v1 package is the byte-locked MBL-2232 contract. Native iOS and wrapper
fixtures vendor the complete 18-file package and verify it before invoking the
non-overridable canonical validator. A field, seat, or enum change requires
coordinated propagation and a schema version change. There is no compatibility
parser for rejected pre-v1 formats.

The native sample-only producer under `Apps/Common/Source/Diagnostics/` emits
this wire shape, but compile/link proof remains L1. It is not L2/L3 evidence
until an external scenario controller performs the documented simulator or
device stimulus, app-container output handoff, zero-drop receipt collection,
exact provenance construction, and complete validator pass. Producer scope and
unsupported seats are recorded in `IOS27-LIFECYCLE-CALLBACK-CONTRACT.md`.
