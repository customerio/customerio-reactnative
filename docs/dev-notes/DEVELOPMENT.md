# Development

### Getting started

Make sure your you have a working [React Native development environemnt](https://reactnative.dev/docs/set-up-your-environment). Make sure to 


## Work on SDK Locally

1. Clone the SDK `git clone https://github.com/customerio/customerio-reactnative --recursive`
2. `cd customerio-reactnative`
3. `yarn install`
4. `yarn example pods`
5. to run either the APN or FCM apps `yarn example ios-apn` or `yarn example ios-cfm`

At this point you can chose whether to run the iOS/Android example apps and you can open the native project for each in `example/ios` and `example/android` if you want to be able to debug the native code with the native development IDE.