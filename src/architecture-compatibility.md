# React Native New Architecture Compatibility

This document explains how the CustomerIO React Native SDK maintains compatibility with both the old and new React Native architectures.

## Overview

React Native's New Architecture introduces TurboModules, which provide a more efficient and type-safe way to bridge JavaScript and native code. However, not all React Native apps will be using the new architecture immediately, so it's important to maintain backward compatibility.

## Architecture Adapter

The SDK includes an architecture adapter (`architecture-adapter.js`) that detects which architecture is being used and provides the appropriate implementation. This allows the SDK to work with both the old architecture (using the legacy NativeModules system) and the new architecture (using TurboModules).

### How It Works

1. The adapter checks if the New Architecture is enabled by looking for the `RN$Bridgeless` global variable.
2. If the New Architecture is enabled, it uses the TurboModuleRegistry to get the TurboModule implementation.
3. If the New Architecture is not enabled or the TurboModule is not available, it falls back to the legacy NativeModule implementation.

```javascript
function isTurboModuleEnabled() {
  return global.RN$Bridgeless === true;
}

function getCustomerIOModule() {
  if (isTurboModuleEnabled()) {
    // New Architecture - TurboModule
    try {
      const { TurboModuleRegistry } = require('react-native');
      const CustomerIOTurboModule = TurboModuleRegistry.get('CustomerIOModule');
      if (CustomerIOTurboModule != null) {
        return CustomerIOTurboModule;
      }
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
```

## Native Implementation

### iOS

For iOS, both the legacy NativeModule and TurboModule implementations are included in the SDK:

1. **Legacy NativeModule**: Implemented in `ios/wrappers/CioRctWrapper.swift`
2. **TurboModule**: Implemented in `ios/wrappers/turbo/RCTCustomerIOTurboModule.mm`

The TurboModule implementation is only used when the New Architecture is enabled.

### Android

For Android, both the legacy NativeModule and TurboModule implementations are included in the SDK:

1. **Legacy NativeModule**: Implemented in `android/src/main/java/io/customer/reactnative/sdk/CustomerIOReactNativeModule.kt`
2. **TurboModule**: Implemented in `android/src/main/java/io/customer/reactnative/sdk/turbo/CustomerIOTurboModule.kt`

The TurboModule implementation is only used when the New Architecture is enabled.

## JavaScript/TypeScript Implementation

The JavaScript/TypeScript implementation uses the architecture adapter to get the appropriate native module implementation:

```javascript
// Import the architecture adapter
const { getCustomerIOModule } = require('./architecture-adapter');

// Get the appropriate native module based on the architecture
const NativeCustomerIO = getCustomerIOModule();

// Use the native module as before
NativeCustomerIO.initialize(config, args);
```

## TypeScript Considerations

When using TypeScript with the New Architecture, you need to be careful about the module system. The SDK includes TypeScript specifications for the TurboModules in the `src/specs` directory, but these are only used for type checking and are not included in the compiled JavaScript.

## Testing

To test the SDK with both architectures:

1. **Old Architecture**: Use a regular React Native app without enabling the New Architecture.
2. **New Architecture**: Use a React Native app with the New Architecture enabled by setting `newArchEnabled=true` in `gradle.properties` for Android and enabling the New Architecture in Xcode for iOS.

## Troubleshooting

If you encounter issues with the New Architecture:

1. Make sure you have properly set up React Native's New Architecture in your app.
2. Check that the TurboModule implementations are properly registered.
3. Verify that the architecture adapter is correctly detecting the architecture.
4. Look for errors in the native module implementations.