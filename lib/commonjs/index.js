"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.Region = exports.CustomerIO = void 0;
exports.multiply = multiply;

var _reactNative = require("react-native");

const LINKING_ERROR = `The package 'customerio-reactnative' doesn't seem to be linked. Make sure: \n\n` + _reactNative.Platform.select({
  ios: "- You have run 'pod install'\n",
  default: ''
}) + '- You rebuilt the app after installing the package\n' + '- You are not using Expo managed workflow\n';
const CustomerioReactnative = _reactNative.NativeModules.CustomerioReactnative ? _reactNative.NativeModules.CustomerioReactnative : new Proxy({}, {
  get() {
    throw new Error(LINKING_ERROR);
  }

});
var Region;
exports.Region = Region;

(function (Region) {
  Region["US"] = "US";
  Region["EU"] = "EU";
})(Region || (exports.Region = Region = {}));

function multiply(a, b) {
  return CustomerioReactnative.multiply(a, b);
}

class CustomerIO {
  static initialize(siteId, apiKey, region) {
    console.log(region);
    return CustomerioReactnative.initialize(siteId, apiKey, region);
  }

  static testMethod() {
    return CustomerioReactnative.testMethod();
  }

}

exports.CustomerIO = CustomerIO;
//# sourceMappingURL=index.js.map