This is a new [**React Native**](https://reactnative.dev) project, bootstrapped using [`@react-native-community/cli`](https://github.com/react-native-community/cli).

# Getting Started

>**Note**: Make sure you have completed the [React Native - Environment Setup](https://reactnative.dev/docs/environment-setup) instructions till "Creating a new application" step, before proceeding.

## Install all dependencies
First thing, run `yarn install`
then `yarn pods` to install the iOS pods

## Run the iOS app
You can run the app directly from the command line or from Xcode.

### Run from CMD
This app contains two targets, one is set up to use Apple Push Notification Service (APN) and the other uses Firebase Cloud Messaging (FCM)
You can run any of them with one of the two commands
```
yarn ios-apn
# Or
yarn ios-fcm
```

### Run from Xcode
First off, you sill need the Metro server, whic you can run from the command line by running `yarn start`
Then open the `ios/CustomerIO_RN.xcworkspace` file in Xcode and chose one of the two schemes to run the app