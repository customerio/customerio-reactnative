/**
 * This file exports all the TypeScript specifications for the CustomerIO SDK.
 * These specifications define the interface between JavaScript and native code
 * following React Native's New Architecture patterns.
 */

// Export types and enums
export * from './CustomerIOTypes';

// Export module specifications
export type { CustomerIOModuleSpec } from './CustomerIOModuleSpec';
export type { InAppMessagingModuleSpec } from './InAppMessagingModuleSpec';
export type { PushMessagingModuleSpec } from './PushMessagingModuleSpec';
