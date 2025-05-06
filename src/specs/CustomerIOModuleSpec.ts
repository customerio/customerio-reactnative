/**
 * This file defines the TypeScript specification for the CustomerIO core module.
 * It follows React Native's New Architecture patterns for TurboModules.
 */

import type { CioConfig, PackageInfo } from './CustomerIOTypes';

/**
 * CustomerIO Core Module Specification
 * 
 * This interface defines the methods that should be implemented by the native module
 * for core CustomerIO functionality.
 */
interface CustomerIOModuleSpec {
  // Initialization
  initialize(config: CioConfig, packageInfo: PackageInfo): void;
  
  // Identification
  identify(userId: string | null, traits: Record<string, any> | null): void;
  clearIdentify(): void;
  
  // Tracking
  track(name: string, properties: Record<string, any> | null): void;
  screen(title: string, properties: Record<string, any> | null): void;
  
  // Attributes
  setProfileAttributes(attributes: Record<string, any>): void;
  setDeviceAttributes(attributes: Record<string, any>): void;
  
  // Device token management
  registerDeviceToken(token: string): void;
  deleteDeviceToken(): void;
}

export type { CustomerIOModuleSpec };
