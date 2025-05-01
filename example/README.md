# React Native Sample App for Customer.io SDK

This React Native sample app demonstrates how to integrate and use the [Customer.io React Native SDK](https://customer.io/docs/sdk/react-native/). It includes example implementations for push notifications using Apple Push Notification Service (APNs) or Firebase Cloud Messaging (FCM), depending on how the app is initialized.

---

## 📦 SDK Usage Overview

All `CustomerIO.*` calls are located in [`src/App.tsx`](src/App.tsx) for easy reference. Other parts of the app are unrelated to SDK functionality.

---

## 📱 iOS SDK Integration

Key files involved in the native iOS setup:

- [`ios/Podfile`](ios/Podfile): Customer.io and push provider pods
- [`ios/SampleApp/AppDelegate.swift`](ios/SampleApp/AppDelegate.swift): Push initialization and Universal Links
- [`ios/NotificationServiceExtension/NotificationService.swift`](ios/NotificationServiceExtension/NotificationService.swift): Rich push implementation

> **Note:** You'll see FCM- and APN-specific code snippets. This is intentional to demonstrate the setup differences.

---

## 🚀 Build and Run

### Prerequisites

1. **React Native Environment**

   - Follow the [React Native environment setup guide](https://reactnative.dev/docs/environment-setup).
   - Minimum iOS version: **16.4+**

1. **Customer.io Account & Push Configuration**

- If you don't have Customer.io account, [sign up](https://fly.customer.io/signup) for a free account.

1. Follow the [Quick Start Guide](https://docs.customer.io/sdk/react-native/quick-start-guide/) to setup your Customer.io workspace for push notifications and obtain API Key

### Initialize the Project

Run the following one-time setup:

```bash
# Clone the Repo
git clone https://github.com/customerio/customerio-reactnative

cd customerio-reactnative/example
./scripts/sample-apps-init.sh      # Initializes Android + iOS with APN setup
# OR
./scripts/sample-apps-init.sh fcm # Initializes Android + iOS with FCM setup
```

### Add Your Site ID & API Key

Set your credentials in the following files:

- `ios/NotificationServiceExtension/Env.swift`
- `src/env.ts`

### Code Signing and Provisioning

Update provisioning profiles and bundle IDs to match your own app setup.

> **Customer.io dev team:** Search for `RN SampleApp Push Setup` in 1Password to access signing credentials.

### Run the App

```bash
cd customerio-reactnative/example # Navigate to the example folder

npm run ios     # Builds and runs on iOS
npm run android # Builds and runs on Android
```

---

## 🔁 Switching Between APNs and FCM (iOS Only)

To switch the app configurations between APN and FCM:

1. Close Xcode.
2. Navigate to the iOS directory:

   ```bash
   cd customerio-reactnative/example/ios
   ```

3. Run one of the following:
   - For **APNs**:
     ```bash
     bundle exec pod install
     ```
   - For **FCM**:
     ```bash
     PUSH_PROVIDER=fcm bundle exec pod install
     ```

---

## 🛠️ Troubleshooting

### `npm run ios` fails to build

- Common causes include provisioning profile issues or simulator mismatches.
- Best approach: open `ios/SampleApp.xcworkspace` in Xcode to inspect the error.

If it’s a simulator issue:

```bash
cd customerio-reactnative/example # Navigate to the example folder

npm run ios -- --simulator "iPhone 16 Pro (18.0)"
```

Replace with your simulator’s actual name and iOS version.  
To list available simulators:

```bash
xcrun simctl list devices
```

---

## 🧰 Sample App Maintenance

> For Customer.io mobile dev team or other developers interested in the sample app itself.

### App Names

If there is a need to update any of the app names, it should be updated in:

- `ios/SampleApp/BuildSettings/(apn|fcm)/Common.xcconfig`: `INFOPLIST_KEY_CFBundleDisplayName`
- `customerio-reactnative/index.js`: `AppRegistry.registerComponent(...)`
- `customerio-reactnative/example/android/app/src/main/java/io/customer/rn_sample/fcm/MainActivity.kt`: `getMainComponentName`
- `customerio-reactnative/example/src/env.ts.sample`: Keys of the `AppEnvValues` object

### iOS Project Structure

The iOS project supports both APN and FCM targets using `.xcconfig` files and symlinks.

**Key Concepts:**

- `SampleApp.xcodeproj` is untracked and dynamically configured.
- Build settings are managed via dedicated `.xcconfig` files for each variant.
- Running `bundle exec pod install` automates this setup:
  - It invokes methods from the script `scripts/ios_project_setup_utils.rb` which:
    - Creates the `ios/SampleApp.xcodeproj` if it doesn't exist
    - Creates symlinks to the appropriate config files
    - The config files sets app specific configs as well as preprocessor flags like `USE_APN` or `USE_FCM`
- `ios/SampleApp.xcodeproj` is preconfigured to use the symlink of the configs created in the previous steps
- The native code uses the preprocessor flags for conditional imports and logic in native code

This process is triggered through the following command from the `customerio-reactnative/example/ios` folder.

```bash
PUSH_PROVIDER=(apn|fcm) bundle exec pod install
```

### Managing `SampleApp.xcodeproj`

This file is untracked to avoid irrelevant changes from CocoaPods.

To track meaningful edits:

1. Ensure your changes apply to both APN and FCM builds.
2. Run:

   ```bash
   cd customerio-reactnative/example # Ensure you are in the example folder

   ./scripts/track_ios_project_changes.sh
   ```

   This command will:

   - Deintegrate pods
   - Copies `SampleApp.xcodeproj` to `SampleApp.xcodeproj.tracked` to track the changes

To continue development:

```bash
cd customerio-reactnative/example/ios # Ensure you are in the ios folder

PUSH_PROVIDER=(fcm|apn) bundle exec pod install
```

---

## 📚 Resources

- [React Native SDK Docs](https://customer.io/docs/sdk/react-native/)

---

## 🧪 Contributing

Pull requests and feedback are welcome. Please ensure your updates are consistent across both FCM and APN setups.

---
