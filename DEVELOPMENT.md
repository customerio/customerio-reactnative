# Development

### Getting started

Since this SDK is npm package, it does not need to be compiled separately.


## Work on Ami App locally

We use the [Ami App](https://github.com/customerio/amiapp-reactnative) to test the SDK in a real-world environment.

When you install dependencies via yarn/npm in react native app, you can install it from your local machine directly. You need to follow the following steps to use local version of the SDK

1. Go to `package.json` of your react native app
1. Find the SDK dependency i.e. `"customerio-reactnative": "{version}"`
1. Update the SDK version to path of the SDK e.g. `"customerio-reactnative": "../customerio-reactnative"`
1. Run `yarn install` to update dependencies and use local version of SDK instead

### Android

Android SDK can be tested locally by following [instructions from native SDK](https://github.com/customerio/customerio-android/blob/develop/docs/dev-notes/DEVELOPMENT.md#work-on-remote-habits-locally). Once SDK release is installed locally, it can be included in Ami App using any of the following options:

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

iOS SDK cannot be tested locally at this time. You must instead refer to a version of the iOS SDK already released to production. 

If you make changes to native code, it sometimes may not be reflected in the app. View the [Ami App docs](https://github.com/customerio/amiapp-reactnative/blob/HEAD/docs/dev-notes/DEVELOPMENT.md#work-on-sdk-locally) for next steps on getting Ami App to install the SDK from your local directory.  

> Please note that currently there is no script or automation that helps you make the changes, so you should revert the changes in `package.json` and `yarn.lock` for local version of `customerio-reactnative` before pushing any changes to git.
