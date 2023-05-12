# Development

## Getting Started

To get started with the project, you might need several tools to compile on your machine.

- First install IDE or Code Editor you like so you can navigate to code conveniently
  - [Visual Studio Code](https://code.visualstudio.com/) (Recommended) - Code Editor to navigate between project files
  - [Android Studio](https://developer.android.com/studio) and [XCode](https://developer.apple.com/xcode/) (Required) - IDEs for setting up CLI tools and getting suggestions on native code
- Setup react native development environment on your machine by following commands below

> This guide assumes you have [homebrew](https://brew.sh/) installed and combines most of the commands you would need to setup the environment on your machine. If you want to read full guide, visit the [official docs](https://reactnative.dev/docs/environment-setup) -> React Native CLI Quickstart -> Your Development and Target OS

  - Install node using `brew install node` (Node 14 or newer required, prefer LTS versions)
  - Check if you have ruby installed on your machine by running `ruby --version` (React Native uses [this version](/.ruby-version) of Ruby)

> Currently, macOS 12.5.1 is shipped with Ruby 2.6.8, which is not what is required by React Native. We recommend installing some Ruby Manager to have different versions of Ruby installed on your machine without breaking other projects. [React Native docs have listed a few](https://reactnative.dev/docs/environment-setup#ruby), you can choose any of them and skip instructions for Ruby Version Manager if you want to go with a different option.

 - If you do not have required version of ruby installed
   - Install [rbenv](https://github.com/rbenv/rbenv) for managing Ruby versions by running `brew install rbenv ruby-build`
   - Load rbenv in your shell by running `rbenv init` and restarting the shell
   - Make sure you have the required ruby version set locally. You can do this by running `rbenv local 2.7.6`
 - Make sure you have [Xcode Command Line Tools installed](https://stackoverflow.com/a/45566089)

> **Warning**
> 
> **Please make sure you are at root directory of the project before running commands mentioned below**

### Connect the app to a workspace in Customer.io

- Make a copy of `env.sample.js` by running `cp env.sample.js env.js` at project root directory
- Update `env.js` with your `siteId` and `apiKey`

### Install Dependencies

Before running any app, make sure the dependencies are installed by running following command:

```
yarn install
```

In case you add/update dependencies later, you will need to run this command again to install the updated dependencies.

### Android

*Note: It's assumed that you have Android Studio installed on your machine before continuing*

This project requires Firebase setup in order to build the app. You can quickly get the app to build with following command

```
cp android/app/google-services.json.example android/app/google-services.json
```

But to make push notifications work, you need to setup the project and copy correct file. If you are a CIO employee, download `google-services.json` file from Firebase project named *Ami ReactNative*. If you are not an employee, you can follow [Firebase setup instructions](https://firebase.google.com/docs/android/setup) to add a new Android app to your Firebase project. This will give you a `google-services.json` file to download. Save this file at `android/app/google-services`. 

#### Build App - Option 1: Using Command Line

Use the following commands to run the app

```
npx react-native run-android
```

Android app will be launched on physical device if connected using `adb`, if not, it should open an emulator and run the app on it. However, if you have multiple devices connected, you can run on a specific device by running following command:

```
npx react-native run-android --deviceId=DEVICE_ID
```

Where `DEVICE_ID` can be obtained by running `adb devices` command.

#### Build App - Option 2: Using Android Studio

- Open the `android` folder in Android Studio
- Build the app in Android Studio
- Run the app

### iOS

*Note: It's assumed that you have XCode installed on your machine before continuing*

iOS app requires installing libraries using CocoaPods. You can install it by running following commands

```
cd ios
pod install
cd ..
```

Next, follow these steps:

- Jump into `ios` folder and open [`.xcworkspace`](/ios/SampleApp.xcworkspace) file to setup the project
- [Configure iOS Code Signing](https://github.com/customerio/mobile/blob/main/ios_code_signing.md#how-do-i-setup-my-computer-for-code-signing) to download the provisioning profiles and certificates for development to your machine. 

> **Note:**
> Make sure that the deployment target is set to the minimum [required by the iOS SDK](https://github.com/customerio/customerio-ios#readme).

#### Build App - Option 1: Using Command Line

**To run the app on iOS Simulator**

Use the following commands to run the app on iOS Simulator

```
npx react-native run-ios
```
**To run the app on device**

To run using terminal

```
npx react-native run-ios --device "DEVICE_NAME"
```

Where `DEVICE_NAME` can be obtained by running `xcrun xctrace list devices` command.

#### Build App - Option 2: Using XCode

- Open [`.xcworkspace`](ios/SampleApp.xcworkspace) file in `ios` folder
- Select the device from the list of devices available
- Run the app 

# Work on SDK locally

Did you just implement a bug fix or new feature to the [React Native SDK](https://github.com/customerio/customerio-reactnative) that you want to test your change locally in Ami App? Want to work on Ami App *and* the SDK at the same time on your local machine? You can! 

1. Follow the [SDK docs](https://github.com/customerio/customerio-reactnative/blob/HEAD/docs/dev-notes/DEVELOPMENT.md#work-on-amiapp-locally) to setup your SDK for Ami App to install.
1. Changes made in JS/TS file will be visible instantly. However, if you made any changes to native code, you will need to re-run the app and run `yarn upgrade customerio-reactnative` first to include the latest code.<br/>
1. Run the Ami App following the instructions above.

> **Tip:** If you need a clean rebuild, you can do it by removing `node_modules` folder and reinstalling dependencies using `yarn install`. Or you can run npm scripts to reinstall all dependencies and run builds using single command
> <br/>
> <br/>*Android:* `npm run clean-install-android` OR `npm run clean-install-android -- DEVICE_ID`
> <br/>*iOS:* `npm run clean-install-ios` OR `npm run clean-install-ios -- DEVICE_NAME`
