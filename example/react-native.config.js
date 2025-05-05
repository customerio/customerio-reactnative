const path = require('path');
const pkg = require('../package.json');

/** @type import("@react-native-community/cli-types").Config */
module.exports = {
  dependencies: {
    [pkg.name]: {
      root: path.join(__dirname, '..'),

      platforms: {
        // Codegen script incorrectly fails without this
        // So we explicitly specify the platforms with empty object
        ios: {},
        android: {},
      },
    },
  },
};
