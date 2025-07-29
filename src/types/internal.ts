/**
 * Internal-only types used within the Customer.io React Native SDK implementation.
 *
 * Not intended for public use.
 */

/**
 * Arguments passed to native SDK for package identification.
 *
 * Provides metadata about the host environment and SDK version to native
 * CustomerIO SDK for debugging and analytics.
 *
 * @internal
 */
export type NativeSDKArgs = {
  /** The package manager or framework hosting the SDK (ReactNative, Expo) */
  packageSource: string;
  /** Version of the SDK package being used */
  packageVersion: string;
};
