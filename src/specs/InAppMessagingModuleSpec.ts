/**
 * This file defines the TypeScript specification for the CustomerIO In-App Messaging module.
 * It follows React Native's New Architecture patterns for TurboModules.
 */

/**
 * In-App Messaging Module Specification
 *
 * This interface defines the methods that should be implemented by the native module
 * for in-app messaging functionality.
 */
interface InAppMessagingModuleSpec {
  // Dismiss the currently displayed in-app message
  dismissMessage(): void;

  // Event constants
  readonly InAppEventListenerEventName: string;

  // Event types
  readonly Events: {
    readonly MessageShown: string;
    readonly MessageDismissed: string;
    readonly MessageActionTaken: string;
    readonly ErrorWithMessage: string;
  };
}

export type { InAppMessagingModuleSpec };
