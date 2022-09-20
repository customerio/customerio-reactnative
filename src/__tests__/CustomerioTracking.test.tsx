import { NativeModules } from 'react-native';
import { CustomerIO, CustomerioConfig, CustomerIOEnv } from '..';
var pjson = require('../../package.json');

describe('CustomerIO tests', () => {
  describe('initialize', () => {
    it('should call initialize', () => {
      // Arrange
      let pversion = pjson.version ?? '';

      // Act
      CustomerIO.initialize(new CustomerIOEnv());

      // Assert
      expect(NativeModules.CustomerioReactnative.initialize).toHaveBeenCalled();
      expect(
        NativeModules.CustomerioReactnative.initialize
      ).toHaveBeenCalledWith(
        new CustomerIOEnv(),
        new CustomerioConfig(),
        pversion
      );
    });
  });
});
