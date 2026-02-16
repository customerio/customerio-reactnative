# Update Customer.io native SDKs

Update the Customer.io **iOS** and/or **Android** native SDK versions used by this React Native library.

## Where versions are defined

| Platform | File | What to change |
|----------|------|----------------|
| **iOS** | `package.json` | `cioNativeiOSSdkVersion` (and optionally `cioiOSFirebaseWrapperSdkVersion` if needed) |
| **Android** | `android/gradle.properties` | `customerio.reactnative.cioSDKVersionAndroid=x.y.z` |

- iOS version is read by `customerio-reactnative.podspec` and `customerio-reactnative-richpush.podspec` from `package.json`. Firebase wrapper version is read as `cioiOSFirebaseWrapperSdkVersion`.
- Android version is read by `android/build.gradle` as `ext.cioAndroidSDKVersion` from `gradle.properties`.

## Steps

1. **Decide target versions**
   - Check latest releases (optional):
     - iOS: https://github.com/customerio/customerio-ios/releases
     - Android: https://github.com/customerio/customerio-android/releases
   - Use tag version without leading `v` (e.g. `4.1.3`, `4.15.2`).

2. **Update iOS native SDK**
   - In **`package.json`**, set:
     - `"cioNativeiOSSdkVersion": "= X.Y.Z"` (e.g. `"= 4.1.3"`). Keep the `= ` prefix (CocoaPods “any compatible” style).
   - Only change `cioiOSFirebaseWrapperSdkVersion` if the iOS SDK or docs require it.

3. **Update Android native SDK**
   - In **`android/gradle.properties`**, update the line:
     - `customerio.reactnative.cioSDKVersionAndroid=<new version>` (e.g. `4.15.2`). Single `=`, no space.

4. **Verify**
   - From repo root:
     - `npm ci`
