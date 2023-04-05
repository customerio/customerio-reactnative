// Learn more https://docs.expo.io/guides/customizing-metro
const { getDefaultConfig } = require('expo/metro-config');

module.exports = getDefaultConfig(__dirname);

const path = require("path");
// const watchFolders = [
//   //Relative path to packages directory because I'm in yarn workpspaces
//   path.resolve(__dirname + "/../.."),
// ];
module.exports = {
  resolver: {
    extraNodeModules: {},
  },
  transformer: {
    getTransformOptions: async () => ({
      transform: {
        // this defeats the RCTDeviceEventEmitter is not a registered callable module
        inlineRequires: true,
      },
    }),
  },
};