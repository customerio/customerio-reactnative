/**
 * This file provides an adapter layer that works with both the old and new React Native architectures.
 * It detects which architecture is being used and provides the appropriate implementation.
 */

const { NativeModules, Platform } = require('react-native');

// Error message to show when the native module is not properly linked
const LINKING_ERROR =
  `The package 'customerio-reactnative' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

/**
 * Determines if the New Architecture (TurboModules) is enabled
 */
function isTurboModuleEnabled() {
  return global.RN$Bridgeless === true;
}

/**
 * Gets the CustomerIO core module, using either TurboModule or legacy NativeModule
 */
function getCustomerIOModule() {
  if (isTurboModuleEnabled()) {
    // New Architecture - TurboModule
    try {
      const { TurboModuleRegistry } = require('react-native');
      const CustomerIOTurboModule = TurboModuleRegistry.get('CustomerIOModule');
      if (CustomerIOTurboModule != null) {
        return CustomerIOTurboModule;
      }
      // eslint-disable-next-line no-unused-vars
    } catch (e) {
      // TurboModuleRegistry might not be available in older RN versions
      // Fall back to legacy NativeModule
    }
  }

  // Legacy Architecture - NativeModule
  const NativeCustomerIO = NativeModules.NativeCustomerIO;
  if (NativeCustomerIO != null) {
    return NativeCustomerIO;
  }

  // Module not found
  throw new Error(LINKING_ERROR);
}

/**
 * Gets the InAppMessaging module, using either TurboModule or legacy NativeModule
 */
function getInAppMessagingModule() {
  if (isTurboModuleEnabled()) {
    // New Architecture - TurboModule
    try {
      const { TurboModuleRegistry } = require('react-native');
      const InAppMessagingTurboModule = TurboModuleRegistry.get(
        'InAppMessagingModule'
      );
      if (InAppMessagingTurboModule != null) {
        return InAppMessagingTurboModule;
      }
      // eslint-disable-next-line no-unused-vars
    } catch (e) {
      // TurboModuleRegistry might not be available in older RN versions
      // Fall back to legacy NativeModule
    }
  }

  // Legacy Architecture - NativeModule
  const CioRctInAppMessaging = NativeModules.CioRctInAppMessaging;
  if (CioRctInAppMessaging != null) {
    return CioRctInAppMessaging;
  }

  // Module not found
  throw new Error(LINKING_ERROR);
}

/**
 * Gets the PushMessaging module, using either TurboModule or legacy NativeModule
 */
function getPushMessagingModule() {
  if (isTurboModuleEnabled()) {
    // New Architecture - TurboModule
    try {
      const { TurboModuleRegistry } = require('react-native');
      const PushMessagingTurboModule = TurboModuleRegistry.get(
        'PushMessagingModule'
      );
      if (PushMessagingTurboModule != null) {
        return PushMessagingTurboModule;
      }
      // eslint-disable-next-line no-unused-vars
    } catch (e) {
      // TurboModuleRegistry might not be available in older RN versions
      // Fall back to legacy NativeModule
    }
  }

  // Legacy Architecture - NativeModule
  const CioRctPushMessaging = NativeModules.CioRctPushMessaging;
  if (CioRctPushMessaging != null) {
    return CioRctPushMessaging;
  }

  // Module not found
  throw new Error(LINKING_ERROR);
}

module.exports = {
  getCustomerIOModule,
  getInAppMessagingModule,
  getPushMessagingModule,
};
