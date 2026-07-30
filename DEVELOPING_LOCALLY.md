# Developing locally — Visual Notification Inbox UI (SPIKE)

This document covers the local-native-reference setup used by the
`spike/visual-inbox-wrappers` branch, which exposes three native Visual Notification Inbox
UI components to JS:

| JS component | iOS native (SwiftUI) | Android native (Compose) |
| --- | --- | --- |
| `NotificationInboxOverlayView` | `NotificationInboxOverlay()` — iOS 16+ | `NotificationInboxOverlay(modifier)` |
| `NotificationInboxBellView` | `NotificationInboxBell(onTap:)` | `NotificationInboxBell(onClick, modifier)` |
| `NotificationInboxView` | `NotificationInboxView()` | `NotificationInboxView(modifier)` |

These mirror the existing inline-in-app-message embedding (`InlineInAppMessageView`). The
headless inbox **data** API (`getMessages`/`subscribe`/`mark`/`track`) and the global action
`InboxEventListener` are already bridged and are NOT touched here — this is the UI layer only.

## Android (primary build-validation target)

The Visual Notification Inbox UI lives in a native module `:messaginginbox`
(artifact `io.customer.android:messaging-inbox`, package `io.customer.messaginginbox`).
It is not on Maven Central yet, so we serve it from `mavenLocal()` at version `local`.

### 1. Publish the native Android SDK to Maven Local

From the native Android source worktree (read-only reference repo):

```bash
cd /path/to/wt-759-sample   # branch: inbox-sample-listener
IS_DEVELOPMENT=true ./gradlew publishToMavenLocal
```

This publishes **all** CIO modules at version `local`, including `messaging-inbox`. Its Jist
dependency (`io.customer.android:jist`) is resolved from Maven Central (alpha).

### 2. Point this repo's Android native dep at `local`

Already wired on this branch:

- `android/cio-core.gradle` adds:
  `api "io.customer.android:messaging-inbox:$cioAndroidSDKVersion"`
- `android/gradle.properties` sets `customerio.reactnative.cioSDKVersionAndroid=local`
  (revert to a released version, e.g. `4.17.0`, to go back to normal builds)
- `android/build.gradle` enables Jetpack Compose (the `org.jetbrains.kotlin.plugin.compose`
  plugin + `buildFeatures { compose true }` + Compose BOM deps) because the view managers host
  the native `@Composable` inbox components inside a `ComposeView`.
- `example/android/build.gradle` already has `mavenLocal()` in `allprojects.repositories`.
- `example/android/app/build.gradle` enables **core library desugaring**
  (`coreLibraryDesugaringEnabled true` + `com.android.tools:desugar_jdk_libs`), required by
  `messaging-inbox` and its Jist dependency.

### 3. Build / validate

The React Native **library module** is the primary validation target and compiles green:

```bash
cd example/android
./gradlew :customerio-reactnative:compileDebugKotlin
```

This runs Codegen (generating the `NotificationInbox*NativeManagerInterface`/`Delegate`
classes from the specs in `src/specs/components/`) and compiles the new Kotlin view managers
+ Compose-hosted views.

#### Full app build — known environment friction

`./gradlew :app:assembleDebug` can fail in this environment for reasons **unrelated to the
wrapper code**:

1. **Socket Firewall corrupts `autolinking.json`.** The `sfw` PATH wrapper intercepts the
   `npx @react-native-community/cli config` call that the RN Gradle plugin uses to generate
   `example/android/build/generated/autolinking/autolinking.json`, prepending a
   `Protected by Socket Firewall` banner and appending a `=== Socket Firewall ===` footer,
   which makes the JSON unparseable. Workaround: regenerate, then strip the non-JSON noise:

   ```bash
   cd example/android
   ./gradlew :app:generateAutolinkingNewArchitectureFiles --rerun-tasks
   python3 - <<'PY'
   import json
   p='build/generated/autolinking/autolinking.json'
   raw=open(p).read()
   obj,_=json.JSONDecoder().raw_decode(raw, raw.index('{'))
   open(p,'w').write(json.dumps(obj, indent=2))
   PY
   # then build WITHOUT regenerating (so the firewall can't re-corrupt it):
   ./gradlew :app:assembleDebug -x generateAutolinkingNewArchitectureFiles
   ```

2. **Stale C++ codegen cache** for unrelated autolinked libs (e.g. `react_codegen_rnscreens`)
   can surface as `ninja: error: unknown target ...` when the autolinking regen is skipped.
   A clean `.cxx` / `react-native clean` resolves it. None of this involves the inbox wrappers.

## iOS — KNOWN BLOCKER (Jist not on CocoaPods trunk)

iOS uses CocoaPods. The bridge source under `ios/wrappers/inbox/` is written and source-correct
(mirrors `ios/wrappers/inapp/inline/`), and the podspec declares the dependency:

```ruby
s.dependency "CustomerIO/MessagingInbox", package["cioNativeiOSSdkVersion"]
```

**Blocker:** `CustomerIO/MessagingInbox` transitively depends on **Jist**, which is not
published to the CocoaPods trunk yet. A full `pod install` of the inbox subspec will therefore
fail to resolve Jist. This is expected and documented rather than forced green here. Once Jist
ships a podspec (or is vendored locally), the iOS bridge compiles via `UIHostingController`
hosting the SwiftUI components.

iOS native SwiftUI source reference: `wt-inbox-ios-fix` (branch `inbox-animation-and-data-fix`),
SPM product `MessagingInbox` (target `CioMessagingInbox`).

## Cross-platform parity note

- `NotificationInboxBellView` `onTap` maps to native `onTap` (iOS) / `onClick` (Android).
- `NotificationInboxOverlayView` exposes **no** panel-presentation prop. Both native overlays own
  panel presentation internally (iOS presents a sheet with system detents), so there is no
  host-facing open/close callback on either platform — the two are at parity here.
- `NotificationInboxOverlayView` requires **iOS 16+** and renders nothing on iOS 15, because the
  native overlay's sheet uses system detents. The bell and list components have no such floor, so
  compose those two if iOS 15 support is needed for a drop-in experience.
- `NotificationInboxView` has no events; message actions flow through the existing global
  `InboxEventListener`.

## To finish (beyond this spike)

- Validate `pod install` + an iOS build. Jist is no longer the blocker (it published to the
  CocoaPods trunk as `Jist 0.1.0`); what remains is that `CustomerIO/MessagingInbox` itself is
  unreleased, so the podspec dependency is commented out and the sample Podfile pins the native
  branch directly.
- Decide intrinsic-sizing behavior for the bell/list (the inline view animates size via
  `onSizeChange`; the inbox components currently fill their RN-assigned bounds).
- Add unit/UI tests and Expo plugin coverage if the components graduate from spike status.
