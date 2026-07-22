# Live Activities (iOS) / Live Notifications (Android)

The `CustomerIO.liveActivities` module shows a live, updating notification driven by a
built-in template. Two templates ship today: **Segments** and **Countdown Timer**.

- **Android** renders built-in templates entirely inside the SDK — **no native code required**.
- **iOS** requires a **Widget Extension** in your app to render (ActivityKit has no data-only
  entry point). The SwiftUI for the built-in templates ships in the SDK, so your widget file is
  ~10 lines (below). Live Activities need **iOS 16.2+** (push-to-start needs 17.2+).

## Enable templates at init

```ts
import { CustomerIO } from 'customerio-reactnative';

CustomerIO.initialize({
  cdpApiKey: '…',
  liveActivities: {
    templates: ['segments', 'countdownTimer'],
    // Android-only branding (iOS branding is compiled into the widget):
    branding: { companyName: 'Acme', accentColorHex: '#FF6D00', logoUrl: 'https://…/logo.png' },
  },
});
```

## Start / update / end

```ts
// Segments
const id = await CustomerIO.liveActivities.start({
  type: 'segments',
  header: 'Order #4021',
  status: 'Preparing your order',
  segmentsTotal: 4,
  segmentsComplete: 1,
});

// update() replaces the whole content-state — pass the FULL desired state each time.
await CustomerIO.liveActivities.update(id, {
  type: 'segments',
  header: 'Order #4021',
  status: 'Out for delivery',
  segmentsTotal: 4,
  segmentsComplete: 3,
});

await CustomerIO.liveActivities.end(id);

// Countdown Timer — endTime is epoch SECONDS
const c = await CustomerIO.liveActivities.start({
  type: 'countdownTimer',
  header: 'Flash Sale',
  title: '50% off ends in',
  endTime: Math.floor(Date.now() / 1000) + 3600,
});
```

`start` resolves with an `activityId` — the only handle you need for `update`/`end`. There is
no lifecycle event callback; delivery/lifecycle metrics are reported to Customer.io automatically.

### Custom types

`startCustom(activityType, data)` starts an app-defined type. **Android** renders it via your
`CustomerIOPushNotificationCallback.createLiveNotification` callback. **On iOS this rejects** —
custom types require a native Widget Extension + `ActivityAttributes` and an `adopt()` call.

### Deep-link / opened metric (iOS)

Call `CustomerIO.liveActivities.handleDeepLinkOpen(url)` from your URL-handling entry point to
report an `opened` metric when the app is opened from a tapped Live Activity. No-op on Android.

## iOS setup (one time)

1. Add the Live Activities pods to your app target's Podfile:
   ```ruby
   pod 'customerio-reactnative/liveactivities'
   ```
2. Add `NSSupportsLiveActivities = YES` to your app's `Info.plist`.
3. Add a **Widget Extension** target (File ▸ New ▸ Target ▸ Widget Extension). In its Podfile
   target, add:
   ```ruby
   pod 'CustomerIO/LiveActivitiesTemplates'
   pod 'CustomerIO/LiveActivitiesAttributes'
   ```
4. Replace the generated widget bundle with the built-in templates:
   ```swift
   import WidgetKit
   import CioLiveActivities_Templates   // ships CIOSegmentsLiveActivity, CIOCountdownTimerLiveActivity
   import CioLiveActivities_Attributes

   @main
   struct CIOLiveActivitiesWidgets: WidgetBundle {
       var body: some Widget {
           CIOSegmentsLiveActivity()
           CIOCountdownTimerLiveActivity()
       }
   }
   ```

> Expo apps can generate the widget extension automatically via the config plugin (planned).

## Android setup

Nothing beyond the standard `messaging-push-fcm` setup — built-in templates render in-SDK. For
API 36+ the SDK uses `Notification.ProgressStyle`; older versions fall back to a native progress
notification.
