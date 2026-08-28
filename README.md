<p align="center">
  <a href="https://customer.io">
    <img src="https://avatars.githubusercontent.com/u/1152079?s=200&v=4" height="60">
  </a>
</p>

[![npm version](https://img.shields.io/npm/v/customerio-reactnative.svg)](https://www.npmjs.com/package/customerio-reactnative)
[![npm downloads](https://img.shields.io/npm/dm/customerio-reactnative)](https://www.npmjs.com/package/customerio-reactnative)
![min Android SDK version is 21](https://img.shields.io/badge/min%20Android%20SDK-21-green)
![min iOS version is 13](https://img.shields.io/badge/min%20iOS%20version-13-blue)
![min Swift version is 5.3](https://img.shields.io/badge/min%20Swift%20version-5.3-orange)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.0-4baaaa.svg)](CODE_OF_CONDUCT.md)

# Customer.io React Native SDK

The official Customer.io SDK for React Native enables you to integrate mobile messaging features—like in-app messaging and push notifications—into your app. These features can be triggered by events sent through the SDK and configured using your Customer.io campaigns.

> 📖 Full documentation: [customer.io/docs/sdk/react-native](https://customer.io/docs/sdk/react-native/)  
> 🧪 Example apps: [see the `/example` directory](/example)

---

## Installation

```bash
npm install customerio-reactnative
```

If a CocoaPods build reports that a generated dependency target is below the deployment range
supported by Xcode, follow the [deployment-target normalization guide](docs/cocoapods-deployment-target-normalization.md).

---

## SDK Initialization

Here’s a simplified example showing how to initialize the SDK to enable most mobile features:

```ts
import {
  CustomerIO,
  CioConfig,
  CioLogLevel,
  CioRegion,
} from 'customerio-reactnative';

useEffect(() => {
  const config: CioConfig = {
    cdpApiKey: 'your-cdp-api-key', // Required
    migrationSiteId: 'your-site-id', // Optional, for migrating from older SDKs
    region: CioRegion.US, // Or CioRegion.EU
    logLevel: CioLogLevel.debug,
    trackApplicationLifecycleEvents: true,
    inApp: {
      siteId: 'your-site-id', // Required for in-app messaging
    },
    push: {
      android: {
        pushClickBehavior: 'ActivityPreventRestart', // Optional
      },
    },
  };

  CustomerIO.initialize(config);
}, []);
```

> 🔑 For help finding your credentials, check out the [Quick Start Guide](https://customer.io/docs/sdk/react-native/quick-start-guide/#step-1).

---

## 📲 Push Notifications

This SDK supports [rich push notifications](https://customer.io/docs/sdk/react-native/rich-push/) using Firebase (for Android) and either Firebase or APNs (for iOS). Follow our [push setup guide](https://customer.io/docs/sdk/react-native/push/) to configure your project for push.

On iOS, a React Native 0.88+ `UIScene` host using the acknowledged handler must declare that ownership before React Native starts. This API is not used on Android or by AppDelegate-only hosts. Call this first in `scene(_:willConnectTo:options:)` so cold destinations wait for the JavaScript handler instead of entering the legacy `Linking` path:

```swift
NativeCustomerIO.configureAcknowledgedSceneDeepLinkRouting()
```

Register the app's Customer.io deep-link handler before calling `CustomerIO.initialize`. Return
`true` after routing a URL. Return `false` to let the native SDK try the host AppDelegate, then pass
a host-owned custom scheme to React Native `Linking` or open other URLs through the system. If your
handler might decline an app-owned custom scheme, keep a `Linking` URL listener registered for that
fallback. A thrown error, rejected promise, missing handler, or handler timeout follows the same
native fallback. Cold URLs wait up to ten seconds for registration and are replayed once the handler
is ready. After delivery, the handler has ten seconds to settle; after that, fallback runs and a late
result is ignored.

```typescript
const subscription = CustomerIO.setDeepLinkHandler(async (url) => {
  if (!canRouteInApp(url)) {
    return false;
  }

  await routeInApp(url);
  return true;
});

CustomerIO.initialize(config);
```

Remove the returned subscription when the routing owner is torn down. If no replacement handler
registers, later destinations wait for the readiness timeout and then use the native fallback.

The existing `Linking` path remains available for backward compatibility. Keep
`NativeCustomerIO.configureSceneDeepLinkRouting()` in your SceneDelegate, then signal readiness
after registering the listener:

```typescript
const subscription = Linking.addEventListener('url', ({ url }) => {
  // Route the URL in your app.
});
CustomerIO.setDeepLinkRoutingReady();
```

This older path cannot acknowledge whether JavaScript handled the URL, so the SDK cannot safely fall back after it publishes a `Linking` event. Prefer `setDeepLinkHandler` for new UIScene integrations. Older React Native versions and AppDelegate-only hosts keep their existing deep-link integration.

Expo apps keep the `Linking` path. With config-plugin auto-initialization, register the app's
`Linking` listener, then call `CustomerIO.setDeepLinkRoutingReady()` after the router is ready. The
Expo plugin configures its native scene lifecycle automatically, so Expo app code does not call a
native configuration method. Apps using JavaScript initialization register the router before
`CustomerIO.initialize`; initialization marks Linking ready automatically.

This integration applies after the host has adopted React Native's UIScene lifecycle; the plugin does not replace React Native's root application lifecycle.

This release's compatibility scope is one simultaneous window scene. Multiple simultaneous React Native window scenes are not supported. React Native's URL notification is process-wide, so SDK-published destinations may reach every connected React Native instance rather than one selected window.

---

## 🔴 Live Activities

Enable the activity types you use under the `liveNotifications` key of your SDK config. On iOS, also add `NSSupportsLiveActivities` to your app's `Info.plist`, the `liveactivities` pod subspec, and a Widget Extension that renders the SDK's built-in templates. Without the `Info.plist` key, iOS refuses to start any activity:

```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

**One manual step is required on iOS.** Forward every opened URL to the SDK from the host's active lifecycle, or taps on a Live Activity are not attributed. `NativeLiveActivities` comes from the wrapper pod, so import it. This only compiles once the `liveactivities` subspec is installed.

For an AppDelegate host:

```swift
import customerio_reactnative
import React

extension AppDelegate {
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    // Reports an `opened` metric and returns the deep link to route to. A non-Customer.io URL comes
    // back unchanged; `nil` means the activity carried no deep link, so there is nothing to open.
    guard let routableUrl = NativeLiveActivities.handleWidgetUrl(url) else { return true }
    return RCTLinkingManager.application(app, open: routableUrl, options: options)
  }
}
```

A React Native `AppDelegate` conforms to `UIApplicationDelegate` directly rather than subclassing, so this method is not an `override`, and the URL is passed on to `RCTLinkingManager` instead of `super`. See [the sample app's `AppDelegate.swift`](/example/ios/SampleApp/AppDelegate.swift) for this in context.

For a `UIScene` host, handle both lifecycle paths. At scene connection, pass the connection options through the wrapper so a cold Live Activity tap is attributed and its destination enters the acknowledged Customer.io router. Ordinary app links remain in React Native launch options for `Linking`:

```swift
import customerio_reactnative

reactNativeFactory?.startReactNative(
  withModuleName: "YourApp",
  in: window,
  launchOptions: NativeLiveActivities.reactNativeLaunchOptions(from: connectionOptions)
)
```

Then replace the ordinary React Native URL-forwarding body in the existing `SceneDelegate` for warm opens. This reports Live Activity taps, sends Customer.io destinations through the configured Customer.io router, and forwards ordinary app links to React Native `Linking`:

```swift
import customerio_reactnative

func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
  for context in URLContexts {
    NativeLiveActivities.handleAndRouteWidgetUrl(context.url)
  }
}
```

Do not also pass those URLs to `RCTLinkingManager`. The helper already routes them through the
Customer.io bridge, and forwarding them again can deliver the same URL twice.

Android needs no equivalent native step.

For Expo Router, unwrap the URL once in the app's top-level `app/+native-intent.tsx` file:

```typescript
import { CustomerIO } from 'customerio-reactnative';

export async function redirectSystemPath({ path }: { path: string }) {
  return CustomerIO.liveActivities.handleWidgetUrl(path);
}
```

This reports the opened event, returns the customer's destination, preserves ordinary URLs, and
returns `null` for a Customer.io tracking URL without a destination. Do not also call the helper
from a `Linking` listener because processing the same tracking URL twice reports two opened events.
Expo apps without Expo Router can apply the helper once in their central `Linking` initial-URL and
subscription pipeline.

---

## Identify Users, Track Events, and More

Customer.io helps you personalize your mobile experience:

- 👤 [Identify users](https://customer.io/docs/sdk/react-native/identify/) to associate events and devices with profiles
- 📊 [Track events](https://customer.io/docs/sdk/react-native/track-events/) to trigger messaging based on user behavior
- 💬 [In-App Messages](https://customer.io/docs/sdk/react-native/in-app/) are server-driven and blend seamlessly with your app

---

## Contributing

We welcome contributions! To get started:

1. Review our [example app](/example) to help with local development.
2. Follow our [Code of Conduct](CODE_OF_CONDUCT.md).

---

## License

[MIT](LICENSE)
