import { NativeModules, Platform } from 'react-native';
const LINKING_ERROR = `The package 'customerio-reactnative' doesn't seem to be linked. Make sure: \n\n` + Platform.select({
  ios: "- You have run 'pod install'\n",
  default: ''
}) + '- You rebuilt the app after installing the package\n' + '- You are not using Expo managed workflow\n';
const CustomerioReactnative = NativeModules.CustomerioReactnative ? NativeModules.CustomerioReactnative : new Proxy({}, {
  get() {
    throw new Error(LINKING_ERROR);
  }

});
var Region;

(function (Region) {
  Region["US"] = "US";
  Region["EU"] = "EU";
})(Region || (Region = {}));

export function multiply(a, b) {
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

export { CustomerIO, Region };
//# sourceMappingURL=index.js.map