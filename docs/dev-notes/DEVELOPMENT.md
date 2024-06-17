# Development

### Getting started

Make sure your you have a working [React Native development environemnt](https://reactnative.dev/docs/set-up-your-environment). Make sure to 


## Work on SDK Locally

1. Firt thing you will need to clone the repo and its submodules
```bash
git clone https://github.com/customerio/customerio-reactnative --recursive
```
2. Then run the following commands in order
  - `cd customerio-reactnative`
  - `yarn install`
  - `yarn example pods` This is required only if you want to run the iOS sample app
  - `yarn example start`

At this point you can chose whether to run the iOS/Android example apps and you can open the native project for each in `example/ios` and `example/android` if you want to be able to debug the native code with the native development IDE.