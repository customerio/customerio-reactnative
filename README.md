<p align=center>
  <a href="https://customer.io">
    <img src="https://avatars.githubusercontent.com/u/1152079?s=200&v=4" height="60">
  </a>
</p>

[![npm version](https://img.shields.io/npm/v/customerio-reactnative.svg)](https://www.npmjs.com/package/customerio-reactnative)
[![npm downloads](https://img.shields.io/npm/dm/customerio-reactnative)](https://www.npmjs.com/package/customerio-reactnative)
![min Android SDK version is 21](https://img.shields.io/badge/min%20Android%20SDK-21-green)
![min ios version is 13](https://img.shields.io/badge/min%20iOS%20version-13-blue)
![min swift version is 5.3](https://img.shields.io/badge/min%20Swift%20version-5.3-orange)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.0-4baaaa.svg)](code_of_conduct.md) 

# Customer.io React Native SDK

This is the official Customer.io SDK for React Native.

You'll find our [complete SDK documentation at https://customer.io/docs/sdk/react-native](https://customer.io/docs/sdk/react-native/). This readme only contains basic information to help you install and initialize the SDK.

## Install and initialize the SDK

1. Open your terminal and run `npm install customerio-reactnative`
1. Add iOS dependencies to your project by going to the iOS subfolder and running `pod install`. 

   Make sure your deployment target is set to at least 13.0. Before you perform this step, you may want to update your podfile to support [APNs and/or FCM push notifications](https://customer.io/docs/sdk/react-native/push/#install-the-push-package) and [rich push](https://customer.io/docs/sdk/react-native/rich-push/#rich-push) respectively.

1. For Android, include [google-services-plugin](https://developers.google.com/android/guides/google-services-plugin) by adding the following lines to the project-level `android/build.gradle` file:  
      ```groovy
      buildscript {
         repositories {
            // Add this line if it isn't already in your build file:
            google()  // Google's Maven repository
         }

         dependencies {
            // Add this line:
            classpath 'com.google.gms:google-services:<version-here>'  // Google Services plugin
         }
      }

      allprojects {
         repositories {
            // Add this line if it isn't already in your build file:
            google()  // Google's Maven repository
         }
      }
      ```

1. Add the following line to `android/app/build.gradle`:
   ```groovy
   apply plugin: 'com.google.gms.google-services'  // Google Services plugin
   ``` 
1. Download `google-services.json` from your Firebase project and copy the file to `android/app/google-services.json`.

1. Return to the main folder and run your application:
   * **iOS**: `npx react-native run-ios`
   * **Android**: `npx react-native run-android`

1. Add an import statement to your project for the react native library. We haven't included it below, but you can import `CioLogLevel` to set log outputs to something other than `error`; this may help you debug your application.
   ```javascript 
   import { CustomerIO, CustomerioConfig, CustomerIOEnv, CioLogLevel, Region } from 'customerio-reactnative';
   ```
1. In `useEffect`, initialize the package with your `CustomerioConfig` options and `CustomerIOEnv` variables. You can find your Site ID and API Key credentials—or create new ones—under *Data & Integrations* > *Integrations* > *Customer.io API*:
   ```javascript
   useEffect(() => {
      const data = new CustomerioConfig()
      data.logLevel = CioLogLevel.debug
      // In-app messages are optional and disabled by default
      // To enable in-app messages, set enableInApp to true
      data.enableInApp = true

      const env = new CustomerIOEnv()
      env.siteId = Env.siteId
      env.apiKey = Env.apiKey
      // Region is optional, defaults to Region.US. Use Region.EU for EU-based workspaces.
      env.region = Region.US

      CustomerIO.initialize(env, data) 
   }, [])
   ```

# More information

See our complete SDK documentation at [https://customer.io/docs/sdk/react-native/](https://customer.io/docs/sdk/react-native/)

# Contributing

Thanks for taking an interest in our project! We welcome your contributions. Check out [our development instructions](docs/dev-notes/DEVELOPMENT.md) to get your environment set up and start contributing.

We value an open, welcoming, diverse, inclusive, and healthy community for this project. We expect all  contributors to follow our [code of conduct](CODE_OF_CONDUCT.md). 

# License

[MIT](LICENSE)
