# MBL-2232 React Native iOS lifecycle producer

Status: L0 source inspection and L1 compile/link evidence only. No canonical L2/L3
capture is claimed.

The example app contains exactly one optional native Swift lifecycle stream. It is disabled unless
the harness supplies the complete `CIO_LIFECYCLE_*` context required by the canonical
contract. It writes canonical NDJSON to `CIO_LIFECYCLE_OUTPUT_PATH` and writes the stream
receipt to the sibling `.receipt.json` path.

The harness must explicitly provide `CIO_LIFECYCLE_HOST_TOPOLOGY=app-delegate-only`
and one canonical `CIO_LIFECYCLE_ACTIVATION_OCCURRENCE_ID`. The example has no
scene manifest or scene delegate, and the recorder places that harness-issued
occurrence on every non-control record. A UIScene claim fails closed instead of
being inferred from missing callbacks.

The implementation deliberately has no JavaScript producer, lifecycle receipt, aggregate,
or `initialProperties` handoff. It also adds no application, scene, notification-center, or
push delegate. This ticket does not change the published wrapper under `ios/`.

## Existing seats recorded

The sample AppDelegate records only callbacks and routing calls that already exist on
`origin/main`:

- `application.did-finish-launching`
- `application.open-url`, followed by `host.route-url` intent/result
- `customerio.route-deep-link` intent/result when the existing Live Activity URL helper is
  called with a `cio-live-activity` URL
- `application.continue-user-activity`, followed by `host.route-user-activity` intent/result

The launch callback is emitted only for the contract's seven cold-start scenarios. Warm and
native-only scenarios still launch the harness process, but they must not contain a cold
external-entry seat.

The native shared `LifecycleTracePlatformProbeObserver` can receive the canonical
Customer.io notification-center and registration probe events when the separately audited
temporary source patch is applied to the native dependency. The sample does not duplicate
those push seats in its existing no-op APN/FCM callback methods.

The four shared support sources are byte copies of native's post-format, post-build frozen
files. The focused Node test pins their SHA-256 values:

| File                           | SHA-256                                                            |
| ------------------------------ | ------------------------------------------------------------------ |
| `LifecycleTraceEvidence.swift` | `f0719e181d7e1ff0423703e86ca9bcc50a99e98111da99dd357fdf09f9ceef87` |
| `LifecycleTraceModel.swift`    | `62d6d8c3b50635a1a5687e535df4b13606b57a71a0106b419bc274819cf6c46c` |
| `LifecycleTraceProbe.swift`    | `b3cb7c92594f555f326dc6410de33e2528382258cd691cf3fb8f2619c9bce580` |
| `LifecycleTraceRecorder.swift` | `9000c4667164cbc8fd2d0f25d938a1182660a2b0bf400f9166e0d8d86f1e458f` |

The focused test separately pins the native-owned contract sync tool at
`03c48a30b287c58e5b611388980928ea08eb91385b52ac5e4dbdb1d32a23db28`.

The killed-state workaround remains behaviorally unchanged, including its inner
`launchOptions` shadow. The outer dictionary passed to `startReactNative` is not repaired or
replaced by this diagnostic work.

This bounded producer can close custom-URL, universal-link, and Live Activity tap scenarios
through the existing host routing calls. With the separately audited native source patch it
can also close push-tap, local-notification-tap, token-registration, and
registration-failure scenarios through existing provider seats. It intentionally cannot
close icon launch, foreground notification, quick-action, background-fetch,
background/foreground lifecycle, or notification-settings scenarios because this sample has
no existing terminal seat for them and this ticket does not invent one.

## Build-stack dependency

The restored base branch's React Native config lets autolinking choose the rich-push
podspec as the primary package podspec. CocoaPods then creates an empty aggregate for
`customerio-reactnative`, and the sample app fails before this fixture is typechecked with
`no such module 'customerio_reactnative'`. MBL-2278 commit
`adcc646d8dd1dd6986806d9f1a06b117b633772e` fixes that graph by explicitly selecting
`customerio-reactnative.podspec` in `example/react-native.config.js`. APN and FCM build
validation for this producer must include that exact stacked change. This ticket does not
duplicate or partially port MBL-2278's normalization work.

The real `example/ios/SampleApp.xcodeproj` is generated and untracked. A reviewer
with an existing local project must remove and regenerate it from
`SampleApp.xcodeproj.tracked` before building, so stale local project wiring
cannot omit the four fixture sources.

## Evidence boundary

The checked-in example at the contract's audited standalone repository commit resolves
React Native 0.83.6. The immutable `pinned_content_commit` in
`ios27-lifecycle-contract-v1.lock.json` identifies the reviewed 18-file
contract. The lock and sync tool are byte-identical to the native owner. This
work keeps the restored 0.83.6 dependency graph.
Until a simulator capture passes the relational validator with a valid manifest and
receipt, the evidence remains L0 source inspection and L1 compilation only. APNs delivery
and registration on a physical device remain L3-only.

Use Node 20 for the focused source test:

```sh
CIO_LIFECYCLE_BASE_REF="$(git rev-parse origin/<current-pr-base>)" \
  mise x node@20 -- node --test example/scripts/lifecycle-trace-native-test/wiring.test.mjs
```

For the current stack, `<current-pr-base>` is
`codex/mbl-2278-cocoapods-target-normalization`.

Verify the byte-identical canonical bundle from the repository root:

```sh
python3 scripts/ios27_lifecycle_contract.py verify --root .
```
