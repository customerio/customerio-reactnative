import { Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'customerio-reactnative' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

/**
 * Ensures the native module is available, otherwise throws a helpful linking error.
 */
export function ensureNativeModule<NativeModule>(
  nativeModule: NativeModule | null
): NativeModule {
  if (!nativeModule) {
    throw new Error(LINKING_ERROR);
  }

  return nativeModule;
}

/**
 * Calls a method on a native module with type-safe access.
 */
export const callNativeModule = <Spec, Result>(
  nativeModule: Spec,
  fn: (native: Spec) => Result
): Result => {
  return fn(nativeModule);
};
