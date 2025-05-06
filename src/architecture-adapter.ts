/**
 * This file provides an adapter layer that works with both the old and new React Native architectures.
 * It detects which architecture is being used and provides the appropriate implementation.
 */

const { NativeModules, Platform } = require('react-native');
// @ts-ignore - TurboModuleRegistry may not be available in older RN versions
const TurboModuleRegistry = require('react-native').TurboModuleRegistry;

// TypeScript declaration for global object used in RN architecture detection
declare const global: { RN$Bridgeless?: boolean };

// Import types for TypeScript type checking only
// These won't be included in the compiled JavaScript
import type { CustomerIOModuleSpec } from './specs/CustomerIOModuleSpec';
import type { InAppMessagingModuleSpec } from './specs/InAppMessagingModuleSpec';
import type { PushMessagingModuleSpec } from './specs/PushMessagingModuleSpec';

// Error message to show when the native module is not properly linked
const LINKING_ERROR =
  `The package 'customerio-reactnative' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

/**
 * Determines if the New Architecture (TurboModules) is enabled
 */
function isTurboModuleEnabled(): boolean {
  return global.RN$Bridgeless === true;
}

/**
 * Gets the CustomerIO core module, using either TurboModule or legacy NativeModule
 */
export function getCustomerIOModule(): CustomerIOModuleSpec {
  if (isTurboModuleEnabled()) {
    // New Architecture - TurboModule
    const CustomerIOTurboModule = TurboModuleRegistry.get(
      'CustomerIOModule'
    ) as CustomerIOModuleSpec;
    if (CustomerIOTurboModule != null) {
      return CustomerIOTurboModule;
    }
  }

  // Legacy Architecture - NativeModule
  const NativeCustomerIO = NativeModules.NativeCustomerIO;
  if (NativeCustomerIO != null) {
    return NativeCustomerIO as CustomerIOModuleSpec;
  }

  // Module not found
  throw new Error(LINKING_ERROR);
}

/**
 * Gets the InAppMessaging module, using either TurboModule or legacy NativeModule
 */
export function getInAppMessagingModule(): InAppMessagingModuleSpec {
  if (isTurboModuleEnabled()) {
    // New Architecture - TurboModule
    const InAppMessagingTurboModule = TurboModuleRegistry.get(
      'InAppMessagingModule'
    ) as InAppMessagingModuleSpec;
    if (InAppMessagingTurboModule != null) {
      return InAppMessagingTurboModule;
    }
  }

  // Legacy Architecture - NativeModule
  const CioRctInAppMessaging = NativeModules.CioRctInAppMessaging;
  if (CioRctInAppMessaging != null) {
    return CioRctInAppMessaging as InAppMessagingModuleSpec;
  }

  // Module not found
  throw new Error(LINKING_ERROR);
}

/**
 * Gets the PushMessaging module, using either TurboModule or legacy NativeModule
 */
export function getPushMessagingModule(): PushMessagingModuleSpec {
  if (isTurboModuleEnabled()) {
    // New Architecture - TurboModule
    const PushMessagingTurboModule = TurboModuleRegistry.get(
      'PushMessagingModule'
    ) as PushMessagingModuleSpec;
    if (PushMessagingTurboModule != null) {
      return PushMessagingTurboModule;
    }
  }

  // Legacy Architecture - NativeModule
  const CioRctPushMessaging = NativeModules.CioRctPushMessaging;
  if (CioRctPushMessaging != null) {
    return CioRctPushMessaging as PushMessagingModuleSpec;
  }

  // Module not found
  throw new Error(LINKING_ERROR);
}
