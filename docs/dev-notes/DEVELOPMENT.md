# Development

### Getting started

Since this SDK is npm package, it does not need to be compiled separately.


## Work on Ami App locally

We use the [Ami App](https://github.com/customerio/amiapp-reactnative) to test the SDK in a real-world environment.

When you install dependencies via yarn/npm in react native app, you can install it from your local machine directly. You need to follow the following steps to use local version of the SDK

- Go to `package.json` of your react native app
- Find the SDK dependency i.e. `"customerio-reactnative": "{version}"`
- Update the SDK version to path of the SDK e.g. `"customerio-reactnative": "../customerio-reactnative"`
- Run `yarn install` to update dependencies and use local version of SDK instead

If you make changes to native code, it sometimes may not be reflected in the app. View the [Ami App docs](https://github.com/customerio/amiapp-reactnative/blob/docs/dev-env/docs/dev-notes/DEVELOPMENT.md#work-on-sdk-locally) for next steps on getting Ami App to install the SDK from your local directory.  

> Please note that currently there is no script or automation that helps you make the changes, so you should revert the changes in `package.json` and `yarn.lock` for local version of `customerio-reactnative` before pushing any changes to git.
