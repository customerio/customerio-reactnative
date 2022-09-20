import { NativeModules } from 'react-native';
import { CioLogLevel, CustomerIO, CustomerioConfig, CustomerIOEnv } from '..';
var pjson = require('../../package.json');

describe('CustomerIO', () => {
  describe('initialize', () => {
    it('should call initialize with only env', () => {
      // Arrange
      let pversion = pjson.version ?? '';
      const env = new CustomerIOEnv();
      env.siteId = '1234';
      env.apiKey = '5678';
      env.organizationId = 'abcdef';

      // Act
      CustomerIO.initialize(env);

      // Assert
      expect(NativeModules.CustomerioReactnative.initialize).toHaveBeenCalled();
      expect(
        NativeModules.CustomerioReactnative.initialize
      ).toHaveBeenCalledWith(env, new CustomerioConfig(), pversion);
    });

    it('should call initialize with env and config', () => {
      // Arrange
      let pversion = pjson.version ?? '';
      const env = new CustomerIOEnv();
      env.siteId = '1234';
      env.apiKey = '5678';
      env.organizationId = 'abcdef';

      const data = new CustomerioConfig();
      data.logLevel = CioLogLevel.debug;
      data.autoTrackDeviceAttributes = true;

      // Act
      CustomerIO.initialize(env, data);

      // Assert
      expect(NativeModules.CustomerioReactnative.initialize).toHaveBeenCalled();
      expect(
        NativeModules.CustomerioReactnative.initialize
      ).toHaveBeenCalledWith(env, data, pversion);
    });
  });

  describe('identify', () => {
    it('should call identify', () => {
      // Arrange
      const emailId = 'test@email.com';
      const userName = 'Ami Test';

      // Act
      CustomerIO.identify(emailId, { first_name: userName });

      // Assert
      expect(NativeModules.CustomerioReactnative.identify).toHaveBeenCalled();
      expect(NativeModules.CustomerioReactnative.identify).toHaveBeenCalledWith(
        emailId,
        { first_name: userName }
      );
    });
  });

  describe('clearIdentify', () => {
    it('should call clearIdentify', () => {
      // Arrange

      // Act
      CustomerIO.clearIdentify();

      // Assert
      expect(
        NativeModules.CustomerioReactnative.clearIdentify
      ).toHaveBeenCalled();
      expect(
        NativeModules.CustomerioReactnative.clearIdentify
      ).toHaveBeenCalledWith();
    });
  });

  describe('track', () => {
    it('should call track with empty data', () => {
      // Arrange

      // Act
      CustomerIO.track('Button Click', {});

      // Assert
      expect(NativeModules.CustomerioReactnative.track).toHaveBeenCalled();
      expect(NativeModules.CustomerioReactnative.track).toHaveBeenCalledWith(
        'Button Click',
        {}
      );
    });

    it('should call track with simple object', () => {
      // Arrange
      const trackEventAttributes = {
        clicked: 'EventWithData',
        name: 'Super Ami',
        country: 'USA',
        city: 'New York',
      };
      // Act
      CustomerIO.track('Data Event', trackEventAttributes);

      // Assert
      expect(NativeModules.CustomerioReactnative.track).toHaveBeenCalled();
      expect(NativeModules.CustomerioReactnative.track).toHaveBeenCalledWith(
        'Data Event',
        trackEventAttributes
      );
    });

    it('should call track with nested object', () => {
      // Arrange
      const shoppingEventAttributes = {
        clicked: 'Clothing',
        product: 'Clothing',
        price: 'USD 99',
        brand: 'Trends',
        detail: {
          color: 'Orange',
          size: 30,
          length: 34,
          isNew: true,
        },
      };

      // Act
      CustomerIO.track('Shopping', shoppingEventAttributes);

      // Assert
      expect(NativeModules.CustomerioReactnative.track).toHaveBeenCalled();
      expect(NativeModules.CustomerioReactnative.track).toHaveBeenCalledWith(
        'Shopping',
        shoppingEventAttributes
      );
    });

    it('should call setDeviceAttributes', () => {
      // Arrange
      const deviceAttributes = {
        type: 'Device attributes',
        detail: {
          location: 'SomeLocation',
          model: 'iPhone 13',
          os: 'iOS 14',
        },
        userAttributes: 'customDeviceAttribute',
        additionalAttributes: 'additionalAttributes',
      };

      // Act
      CustomerIO.setDeviceAttributes(deviceAttributes);

      // Assert
      expect(
        NativeModules.CustomerioReactnative.setDeviceAttributes
      ).toHaveBeenCalled();
      expect(
        NativeModules.CustomerioReactnative.setDeviceAttributes
      ).toHaveBeenCalledWith(deviceAttributes);
    });

    it('should call setProfileAttributes', () => {
      // Arrange
      const profileAttributes = {
        type: 'Profile attributes',
        favouriteFood: 'Pizza',
        favouriteDrink: 'Mango Shake',
        customProfileAttributes: 'customProfileAttribute',
        additionalAttributes: 'additionalAttributes',
      };

      // Act
      CustomerIO.setProfileAttributes(profileAttributes);

      // Assert
      expect(
        NativeModules.CustomerioReactnative.setProfileAttributes
      ).toHaveBeenCalled();
      expect(
        NativeModules.CustomerioReactnative.setProfileAttributes
      ).toHaveBeenCalledWith(profileAttributes);
    });

    it('should call screen', () => {
      // Arrange
      const profileAttributes = {
        type: 'Profile attributes',
        favouriteFood: 'Pizza',
        favouriteDrink: 'Mango Shake',
        customProfileAttributes: 'customProfileAttribute',
        additionalAttributes: 'additionalAttributes',
      };

      // Act
      CustomerIO.screen('Home', profileAttributes);

      // Assert
      expect(NativeModules.CustomerioReactnative.screen).toHaveBeenCalled();
      expect(NativeModules.CustomerioReactnative.screen).toHaveBeenCalledWith(
        'Home',
        profileAttributes
      );
    });

    it('should call screen without data', () => {
      // Arrange

      // Act
      CustomerIO.screen('Home', {});

      // Assert
      expect(NativeModules.CustomerioReactnative.screen).toHaveBeenCalled();
      expect(NativeModules.CustomerioReactnative.screen).toHaveBeenCalledWith(
        'Home',
        {}
      );
    });
  });
});
