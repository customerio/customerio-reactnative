import { CustomerIO } from 'customerio-reactnative';

class CustomerIOService {
  initializeSDK(env, config) {
    CustomerIO.initialize(env, config);
  }

  identifyUser(emailId, data) {
    CustomerIO.identify(emailId, data);
  }

  clearUser() {
    CustomerIO.clearIdentify();
  }

  sendEvent(name, data) {
    CustomerIO.track(name, data);
  }

  setDeviceAttributes(data) {
    CustomerIO.setDeviceAttributes(data);
  }

  setProfileAttributes(data) {
    CustomerIO.setProfileAttributes(data);
  }
}

export default CustomerIOService;
