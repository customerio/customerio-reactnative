# Development

### Getting started

Since this SDK is npm package, it does not need to be compiled separately.


## Work on Ami App locally

When you install dependencies via yarn/npm in react native app, you can install it from your local machine directly. You need to follow the following steps to use local version of the SDK

1. Go to `package.json` of your react native app
1. Find the SDK dependency i.e. `"customerio-reactnative": "{version}"`
1. Update the SDK version to path of the SDK e.g. `"customerio-reactnative": "../customerio-reactnative"`
1. Run `yarn install` to update dependencies and use local version of SDK instead

### Android

Android SDK can be tested locally by following [instructions from native SDK](https://github.com/customerio/customerio-android/blob/develop/docs/dev-notes/DEVELOPMENT.md#publish-sdk-locally). Once SDK release is installed locally, it can be included in Ami App using any of the following options:

### Option 1: Updating in SDK

Updating [`gradle.properties`](https://github.com/customerio/customerio-reactnative/blob/develop/android/gradle.properties) to use local version by updating following line:

```
customerio.reactnative.cioSDKVersionAndroid=local
```

### Option 2: Updating in Ami App

React Native SDK allows overriding SDK version on app side, so Ami App can override the version and use local release instead by [adding the following line in `gradle.properties`](https://github.com/customerio/amiapp-reactnative/blob/main/android/gradle.properties)

```
cioSDKVersionAndroid=local
```

---

### iOS

To test the ReactNative sample apps using local Native iOS SDK, you should follow the following steps:

#### 1. Find the app Podfile

Depending on the app you are working on you need to navigate to either of these pods files:

- Apps/APN/ios/Podfile
- Apps/FCM/ios/Podfile

#### 2. Replace iOS pod declaration

Replace the pods declared for native iOS SDK:
- `pod 'customerio-reactnative/apn', :path => '../node_modules/customerio-reactnative'`
- `pod 'customerio-reactnative-richpush/apn', :path => '../node_modules/customerio-reactnative'`

With either of these:

- To use local checked code use: `install_non_production_ios_sdk_local_path`
- To use changes on a Git branch: `install_non_production_ios_sdk_git_branch`

You will find values in `Podfile`s that are commented, simply comment the one pointing to `node_modules/customerio-reactnative` and replace it with the option you desire.

Do not forget to update the local path on your machine if you are using `install_non_production_ios_sdk_local_path`
