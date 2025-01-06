# Running the sample apps

You can use the following steps to run any of our sample apps.

## Build the SDK

At the root directory of this repository run the following command to build the SDK:

```bash
npm install
```

## Connect the app to a workspace in Customer.io

- Depending on which sample app you want to test, navigate to the directory of that sample app using either of these commands: `cd Apps/APN/` or `cd Apps/FCM`
- Make a copy of `env.sample.js` by running `cp env.sample.js env.js` at sample app root directory
- Make a copy of `Env.swift.example` by running `cp Env.swift.example Env.swift` at sample app `ios` directory (`Apps/APN/ios` or `Apps/FCM/ios`)
- Update env.js with your `siteId` and `cdpApiKey`

## Build one of the sample apps

Depending on which sample app you want to test, navigate to the directory of that sample app using either of these commands:

`cd Apps/APN/` or `cd Apps/FCM`

Then run the following commands:

```bash
npm run preinstall
npm install
```

## Run the sample app

After you have built the app you can then now run it on Android or iOS using any of these commands:

To run Android:

```bash
npx react-native run-android
```

To run iOS:

```bash
npx react-native run-ios
```
