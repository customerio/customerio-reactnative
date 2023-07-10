import { CustomerIO } from 'customerio-reactnative';

class CioManager {
  randomEvent() {
    CustomerIO.track('RandomEvent');
  }

  customEvent(name, data) {
    CustomerIO.track(name, data);
  }

  deviceAttributes(data) {
    CustomerIO.setDeviceAttributes(data);
  }

  profileAttributes(data) {
    CustomerIO.setProfileAttributes(data);
  }

  identifyUser(emailId, data) {
    CustomerIO.identify(emailId, data);
  }

  clearUserIdentity() {
    CustomerIO.clearIdentify();
  }

  initializeCio(env, config) {
    CustomerIO.initialize(env, config);
  }

  buildInfo() {
    return Promise.resolve(
      'Customer.io React Native SDK (0.0.1) Sample App 1 (1)'
    );
  }
}

export default CioManager;
