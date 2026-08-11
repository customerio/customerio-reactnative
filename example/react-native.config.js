const path = require('path');
const pkg = require('../package.json');

/** @type import("@react-native-community/cli-types").Config */
module.exports = {
  dependencies: {
    [pkg.name]: {
      root: path.join(__dirname, '..'),

      platforms: {
        // Codegen fails without explicitly configured platforms. The package
        // also publishes a rich-push podspec, so pin the primary podspec to
        // keep React Native autolinking deterministic.
        ios: {
          podspecPath: path.join(
            __dirname,
            '..',
            'customerio-reactnative.podspec'
          ),
        },
        android: {},
      },
    },
  },
};
