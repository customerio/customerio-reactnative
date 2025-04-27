# Example Apps

This folder contains sample applications demonstrating how to integrate and use the Customer.io React Native SDK on both Android and iOS platforms. Moreover, these apps contains rich push notification setup that works with both Apple's Push Notification Service (APNS) and Firebase Cloud Messaging (FCM).

## Prerequisites

- React Native Dev Environment

  You will need a fully working React Native [Dev Environment](https://reactnative.dev/docs/set-up-your-environment) in order to build and run these apps.

- Push Notifications

  Depending on the platform and push provider you use, you will need to setup the project with your push provider credentials.

- Customer.io Account

  You will need a CDP API Key, which is used to initialize the SDK. You can learn more by visiting our [authentication](https://docs.customer.io/sdk/ios/getting-started/auth/) documentation

- Min iOS Version

  The iOS sample app deployment target is 16.4. Whether you want to run on simulator or a device make sure its iOS version is 16.4+

## Quick Start

For convenient, we packed all the needed steps for first time run in a single script `example/scripts/sample-apps-init.sh`
By default this script will prepare the Android sample app environment. If you want to also prepare iOS dev environment with APN or FCM, you will need to pass an argment named `apn` or `fcm` respectively.
Examples:

```bash
cd example
./scripts/sample-apps-init.sh # Android only
./scripts/sample-apps-init.sh fcm # Android + iOS with FCM setup
./scripts/sample-apps-init.sh apn # Android + iOS with APN setup
```

- Set the CDP API Key
  Update the following files with your CDP API Key

```bash
example/ios/Env.swift
example/src/Env.ts
```

You are good to run the app

```bash
npm run ios # Builds and runs the iOS app
npm run android # Builds and runs the Android app
```

**Note:**
For Customer.io dev team, please search for `React Native Sample App Push Setup` on 1password to learn how to get the code signing certificates

## Switching between FCM and APN on iOS

- Make sure Xcode is closed
- Use the `example/scripts/sample-apps-init.sh` and pass either `apn` of `fcm`
- If you don't want the full setup this script does, you will need to clean up the Pods cache, then rerun the pod install as follow

```bash
cd example/ios
bundle exec pod deintegrate
bundle exec pod cache clean --all
# PUSH_PROVIDER=fcm or PUSH_PROVIDER=apn
# To configure the project for FCM or APN respectively
PUSH_PROVIDER=fcm bundle exec pod install

```

## Step by step setup

The `example/scripts/sample-apps-init.sh` tries to give you a fresh environment by wiping out any existing build/generated files and then reinstall everything.
That's not ideal in all scenarios specailly after the first initial run. Here is a step by step process so you can skip the ones you successfully ran earlier.

```bash
### Common setup regardless of which platform you will try ###
# 1. From the root folder
npm install

# 2. Navigate the example folder
cd example

# 3.A Can be skipped if you ran it before
npm run prepare

# 3.B Can be skipped if you ran `npm run prepare`
npm install

### iOS Project setup ###
# 1. Install gem dependencies
bundle install

# 2. Install the iOS Pods with either of the 2.A or 2.B steps but not both
# 2.A Use if you don't intend to use push notifications or your push provider is Apple's Push Notification Service (APN)
PUSH_PROVIDER=apn bundle exec pod install

# 2.B Use if you are using FCM for push notifications
PUSH_PROVIDER=fcm bundle exec pod install

# 3 You can now run the iOS project
npm run ios

### Android Project setup ###
# 1 Build and Bundle the android project
npm run bundle:android

# 2 Run it
npm run android

```

## Push Notificatoins

If you want to try out push notifications you will need to:

- Refer to your chosen push provider on how to get your credentials
- Update the team and provision profiles in the Xcode project for iOS.
- If you use FCM for iOS you will also need to replace the `example/ios/SampleApp/GoogleService-Info.plist`
- Similarly for Android, you will need to replace the `example/android/app/google-services.json` with the one from your FCM account

## Where to find examples of XX feature/usage

TODO

## Project Setup

TODO: Detail how the project is configured, and how it changes based on the push provider for iOS

## Known Issues

- **Issue:** Running `npm run ios` fails

  By default `npm run ios` will attempt to run on iOS simulator named "iPhone 16 Pro". Which can fail if you don't have simulator with that name or more than one simulator with that name.

  **Solution:**

  1. Run `xcrun simctl list devices` Which will show output like the one below but the devices will differ based on your local setup

  ```
        iPhone 15 Pro (xxx-xx-xxx-xxxx-xxxxxxxx) (Booted)
    -- iOS 18.0 --
    -- iOS 18.1 --
    -- iOS 18.2 --
        iPhone 16 Pro Max (xxx-xx-xxx-xxxx-xxxxxxxx) (Booted)
  ```

  In this output you have 3 `iPhone 15 Pro` simulators each with a different iOS version and only one simulator with the name `iPhone 16 Pro Max` simulator.

  Decide which one to use and open `example/package.json` and update the `ios` script based on your choice.

  2.A If you want to use the `iPhone 15 Pro`, you must specify which iOS version to use. For example if you want to use iOS 18.1, your `ios` script will look like the following

  ```json
  "ios": "react-native run-ios --simulator \"iPhone 15 Pro (18.1)\"",
  ```

  2.B If you want to use the `iPhone 16 Pro Max`, your `ios` script will look like the following

  ```json
  "ios": "react-native run-ios --simulator \"iPhone 16 Pro Max\"",
  ```
