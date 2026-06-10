const path = require('path');
const pkg = require('../package.json');

// Single build-time flag — must agree with example/metro.config.js and the iOS
// Podfile. CIO_ENABLED=0 disables autolinking for customerio-reactnative on
// both platforms, so the native module is not compiled into the app: no native
// code, and none of the library's merged AndroidManifest entries (e.g. the
// POST_NOTIFICATIONS permission) or iOS pods land in the build artifact.
const cioEnabled = process.env.CIO_ENABLED !== '0';

/** @type import("@react-native-community/cli-types").Config */
module.exports = {
  dependencies: {
    [pkg.name]: {
      root: path.join(__dirname, '..'),

      platforms: cioEnabled
        ? {
            // Codegen script incorrectly fails without this
            // So we explicitly specify the platforms with empty object
            ios: {},
            android: {},
          }
        : {
            // Exclude CIO: null disables autolinking on each platform so
            // use_native_modules! / the Android settings plugin skip it.
            ios: null,
            android: null,
          },
    },
  },
};
