import { TurboModuleRegistry, type TurboModule } from 'react-native';
/* eslint-disable @react-native/no-deep-imports */
import type { UnsafeObject } from 'react-native/Libraries/Types/CodegenTypes';

/**
 * Native module specification for CustomerIO React Native SDK
 *
 * This module defines the TurboModule interface for CustomerIO SDK native bridge.
 * Types use basic primitives for React Native Codegen compatibility, while the public
 * API layer provides more specific TypeScript types for better developer experience.
 *
 * The separation allows:
 * - Native bridge compatibility with Codegen constraints
 * - Type-safe public API with proper TypeScript definitions
 * - Alignment between codegen spec and public contract
 *
 * @see https://github.com/facebook/react-native/issues/38769 for Codegen limitations
 */

/**
 * Generic object type for native bridge parameter passing.
 *
 * Used for all complex data structures passed to native methods to ensure
 * React Native Codegen compatibility. The public API layer converts these
 * to proper TypeScript types (CustomAttributes, CioConfig, etc.) for
 * better type safety and developer experience.
 *
 * @internal - Not exported to avoid conflicts with public API types
 */
type NativeBridgeObject = UnsafeObject;

// =============================================================================
// TURBO MODULE SPEC – Defines native bridge interface
// =============================================================================

/**
 * TurboModule specification for CustomerIO SDK native bridge methods.
 * Uses generic Object types for React Native Codegen compatibility.
 */
export interface Spec extends TurboModule {
  initialize(config: NativeBridgeObject, args: NativeBridgeObject): void;
  identify(params?: NativeBridgeObject): void;
  clearIdentify(): void;
  track(name: string, properties?: NativeBridgeObject): void;
  screen(title: string, properties?: NativeBridgeObject): void;
  setProfileAttributes(attributes: NativeBridgeObject): void;
  setDeviceAttributes(attributes: NativeBridgeObject): void;
  registerDeviceToken(token: string): void;
  deleteDeviceToken(): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('NativeCustomerIO');
