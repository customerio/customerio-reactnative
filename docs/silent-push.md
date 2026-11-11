# Silent push

A Customer.io silent push shows nothing. It wakes your app and hands it the text key/value data you set on
the message, so the app can refresh state in the background. The SDK tracks the delivered metric; silent
pushes have no opened metric.

Silent push needs the customerio-reactnative release that adds `setBackgroundPushHandler`, which bundles native
SDKs that support it (Android 5.1.1, iOS 5.2.1). Customer.io sends a silent push to every iOS and Android device
on the profile, so handling it is up to the app. An app that doesn't handle it shows nothing.

Use one route on each platform:

| Your app | Android and iOS |
| --- | --- |
| The Customer.io SDK owns push (APN or FCM through the Customer.io SDK; Expo apps) | `setBackgroundPushHandler` ([details](#with-the-customer-io-sdk)) |
| Uses `@react-native-firebase/messaging` | React Native Firebase's handlers ([details](#with-react-native-firebase)) |

If an app handles silent pushes in React Native Firebase and also sets `setBackgroundPushHandler`, each push can
arrive twice.

## What a silent push carries

Your data arrives as text keys and values, plus two keys Customer.io adds: `CIO-Background-Delivery-ID` (the
delivery ID) and `CIO-Background-Delivery-Token` (the device token the push was sent to).
`setBackgroundPushHandler` strips them and gives you `deliveryId` and `deliveryToken`; React Native Firebase passes
them through in `remoteMessage.data`.

On Android the message is data-only, at the priority set on the message (normal unless you choose high). On iOS
it is a background notification (`content-available: 1`, priority 5). Like a regular push, it has no expiry.

- **Repeats.** The same push can arrive more than once. Key your work on the delivery ID.
- **Time.** Keep the work short. The SDK waits up to 25 seconds for your handler, including the time React Native
  takes to start.
- **Delays.** Android can hold normal-priority messages while the device is idle, and iOS throttles background
  notifications and keeps only the newest for a device that's offline.

## With the Customer.io SDK

Set the handler in your entry file (`index.js`), before `AppRegistry.registerComponent`. On Android, a silent push
that starts your app in the background runs `index.js` without mounting your app, so a handler set inside a
component would miss it.

```js
// index.js
import { AppRegistry } from 'react-native';
import { CustomerIO } from 'customerio-reactnative';
import App from './src/App';

CustomerIO.pushMessaging.setBackgroundPushHandler(async ({ deliveryId, data }) => {
  await refreshAccount(data, { idempotencyKey: deliveryId });
});

AppRegistry.registerComponent('MyApp', () => App);
```

A handler that throws or rejects is logged and counts as finished. Setting a new handler replaces the previous
one, and the returned subscription's `remove()` stops delivery. You need `deliveryToken` only to track delivery
yourself with `CustomerIO.trackMetric` when automatic push tracking is off.

Your handler can run before any component mounts, so `CustomerIO.initialize` in a component may not have run yet.
To call the SDK from the handler, initialize it in `index.js` too.

### Android

Nothing else is needed. The SDK runs your handler in a Headless JS task from a WorkManager job, in the running app
or in a React Native instance it starts in the background. Your `Application` must provide a `ReactHost`, as the
React Native template does.

A push that starts an app that isn't running reaches your handler once your JavaScript has set it at least once.
If a later version of your app stops setting the handler, the first push that finds none within 25 seconds turns
this off, and calling `remove()` on the subscription turns it off right away.

### iOS

Add the Remote notifications background mode: in Xcode, Signing & Capabilities > Background Modes > Remote
notifications, or `remote-notification` under `UIBackgroundModes` in `Info.plist`.

If your `AppDelegate` is wrapped with `CioAppDelegateWrapper`, as in the Customer.io push setup, nothing else is
needed. Once your JavaScript has set the handler, in this launch or an earlier one, the wrapper hands each
Customer.io silent push to it and tells iOS when it's done. Until then, and for every other notification, your app
delegate gets the push as before. If iOS launched the app for the push, it starts your app as usual and the push
waits until JavaScript sets the handler. As on Android, a later version that stops setting the handler turns this
off with the first push that finds none, and `remove()` turns it off right away. iOS doesn't wake an app the person
force-quit.

Apps using Firebase Cloud Messaging with Firebase's app delegate proxy on (the default) need GoogleUtilities
8.1.5 or later, or no background notification reaches `CioAppDelegateWrapper`. Run `pod update GoogleUtilities`,
or set `FirebaseAppDelegateProxyEnabled` to `NO` in `Info.plist`.

If your app delegate isn't wrapped with `CioAppDelegateWrapper`, forward background notifications yourself:

```swift
import customerio_reactnative

func application(
  _ application: UIApplication,
  didReceiveRemoteNotification userInfo: [AnyHashable: Any],
  fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
) {
  if NativeMessagingPush.handleBackgroundPush(userInfo: userInfo, completionHandler: completionHandler) {
    return // A Customer.io silent push. The SDK tracks Delivered and calls completionHandler.
  }
  completionHandler(.noData) // Or pass the notification to your other handlers.
}
```

## With React Native Firebase

Handle Customer.io silent pushes in React Native Firebase's handlers on both platforms, and don't set
`setBackgroundPushHandler`. `messaging().onMessage` receives a silent push while the app is in the foreground,
and `messaging().setBackgroundMessageHandler` while it's in the background or not running. Keep forwarding
messages to Customer.io as you do today, and don't render a silent push yourself:

```js
messaging().setBackgroundMessageHandler(async (remoteMessage) => {
  const handled = await CustomerIO.pushMessaging.onBackgroundMessageReceived(remoteMessage);
  if (remoteMessage.data?.['CIO-Background-Delivery-ID']) {
    // A Customer.io silent push: read your keys from remoteMessage.data.
    await refreshAccount(remoteMessage.data);
    return;
  }
  if (!handled) {
    // Not a Customer.io message: handle it as before.
  }
});
```

On Android, `onMessageReceived` and `onBackgroundMessageReceived` show nothing for a silent push, track Delivered
and resolve `true`. React Native Firebase runs `setBackgroundMessageHandler` by starting a service, which Android 8
and later refuse for a normal-priority message once the app has been in the background for about a minute; then
neither your handler nor Customer.io sees the push. Choose high priority for Android silent pushes on this route.

On iOS, add the Remote notifications background mode as above. `onMessageReceived` and
`onBackgroundMessageReceived` do nothing on iOS and resolve `true`; the SDK tracks Delivered as the push passes
through `CioAppDelegateWrapper`.
