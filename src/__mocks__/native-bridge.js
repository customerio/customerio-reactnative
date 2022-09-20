import { NativeModules } from 'react-native';

NativeModules.CustomerioReactnative = {
  initialize: jest.fn(),
  identify: jest.fn(),
  clearIdentify: jest.fn(),
  track: jest.fn(),
  setDeviceAttributes: jest.fn(),
  setProfileAttributes: jest.fn(),
  screen: jest.fn(),
};
