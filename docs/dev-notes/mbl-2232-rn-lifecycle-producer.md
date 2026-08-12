# MBL-2232 React Native iOS lifecycle producer

Status: L0 source inspection and L1 compile/link evidence only. No canonical L2/L3
capture is claimed.

The example app contains exactly one optional native Swift lifecycle stream. It is disabled unless
the harness supplies the complete `CIO_LIFECYCLE_*` context required by the canonical
contract. It writes canonical NDJSON to `CIO_LIFECYCLE_OUTPUT_PATH` and writes the stream
receipt to the sibling `.receipt.json` path.

The implementation deliberately has no JavaScript producer, lifecycle receipt, aggregate,
or `initialProperties` handoff. It also adds no application, scene, notification-center, or
push delegate. The published wrapper under `ios/` is unchanged.

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

| File | SHA-256 |
| --- | --- |
| `LifecycleTraceEvidence.swift` | `1db44862654643a5feb6209a87e6f7980e8f723e734f713a2f2902812e3f6215` |
| `LifecycleTraceModel.swift` | `cd74c8b0c9ebdda75f5a3045e6ddbe6dc993252aeec7649b84c05c21c43f5ff1` |
| `LifecycleTraceProbe.swift` | `9d48ad49e5fe116e66e0c924bd1aafd3764709d9865115ba5491836d03927956` |
| `LifecycleTraceRecorder.swift` | `5c3ecfb951ab957f1215b45e70cb5aeb358cf3c6b5335ff553e91a65d02b1588` |

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

## Evidence boundary

The checked-in example at the contract's audited standalone repository commit resolves
React Native 0.83.6. Canonical source commit
`5b8c02e4c85203d073a85da8abb2212b19867e68` contains the reviewed 18-file
contract. Native checkout `93b63e81f1a5544342393abe219e701f8dcd0657` supplies its
final relocked bundle and verifier. This work keeps the restored 0.83.6 dependency graph.
Until a simulator capture passes the relational validator with a valid manifest and
receipt, the evidence remains L0 source inspection and L1 compilation only. APNs delivery
and registration on a physical device remain L3-only.

Use Node 20 for the focused source test:

```sh
mise x node@20 -- node --test example/scripts/lifecycle-trace-native-test/wiring.test.mjs
```

Verify the byte-identical canonical bundle from the repository root:

```sh
python3 scripts/ios27_lifecycle_contract.py verify --root .
```
