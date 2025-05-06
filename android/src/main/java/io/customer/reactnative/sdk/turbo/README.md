# CustomerIO React Native SDK - Android TurboModule Implementation

This directory contains the Android implementation of the TurboModules for the CustomerIO React Native SDK. These modules provide a more efficient and type-safe way to bridge JavaScript and native code following React Native's New Architecture patterns.

## Overview

The implementation consists of three main TurboModules:

1. **CustomerIOModule**: Core CDP functionality (identify, track, etc.)
2. **InAppMessagingModule**: In-app messaging functionality
3. **PushMessagingModule**: Push messaging functionality

Each module is implemented as a Kotlin class that implements the TurboModule interface and provides the functionality defined in the corresponding TypeScript specification.

## Files

- `CustomerIOTurboModule.kt`: Implementation of the core CustomerIO functionality
- `InAppMessagingTurboModule.kt`: Implementation of in-app messaging functionality
- `PushMessagingTurboModule.kt`: Implementation of push messaging functionality
- `CustomerIOTurboModulePackage.kt`: Package class that registers the TurboModules with React Native

## Integration

### 1. Automatic Integration

The TurboModules are automatically integrated into your app when you install the CustomerIO React Native SDK. The SDK's `package.json` includes a `codegenConfig` section that tells React Native's codegen which modules to generate code for.

### 2. Manual Integration

If you need to manually integrate the TurboModules, follow these steps:

1. Add the TurboModule files to your Android project
2. Register the `CustomerIOTurboModulePackage` in your app's `MainApplication.java`:

```java
// In your MainApplication.java
@Override
protected List<ReactPackage> getPackages() {
  List<ReactPackage> packages = new PackageList(this).getPackages();
  packages.add(new CustomerIOTurboModulePackage());
  return packages;
}
```

## Usage

The TurboModules are used through the JavaScript interfaces defined in the `src/specs` directory. For example:

```typescript
import { CustomerIOModuleSpec } from 'customerio-reactnative/lib/module/specs';
import { TurboModuleRegistry } from 'react-native';

// Get the native module
const CustomerIO = TurboModuleRegistry.getEnforcing<CustomerIOModuleSpec>('CustomerIOModule');

// Initialize the SDK
CustomerIO.initialize({
  cdpApiKey: 'your-cdp-api-key',
  // other configuration options
}, {
  packageSource: 'ReactNative',
  packageVersion: '1.0.0',
});

// Identify a user
CustomerIO.identify('user-id', {
  email: 'user@example.com',
  // other user traits
});
```

## Troubleshooting

### Common Issues

1. **Module not found**: Make sure the module name in your JavaScript code matches the name exported by the native module. The module names are:
   - `CustomerIOModule` for core functionality
   - `InAppMessagingModule` for in-app messaging
   - `PushMessagingModule` for push messaging

2. **Build errors**: If you encounter build errors, make sure you have properly set up React Native's New Architecture in your app. This includes:
   - Setting `newArchEnabled=true` in your `gradle.properties`
   - Updating your app's `build.gradle` to include the necessary dependencies
   - Running `./gradlew clean` before rebuilding your app

3. **Runtime errors**: If you encounter runtime errors, check the logcat output for more information. Common issues include:
   - Missing or incorrect module names
   - Type mismatches between JavaScript and native code
   - Missing or incorrect method implementations

## Resources

- [React Native New Architecture Documentation](https://reactnative.dev/docs/the-new-architecture/landing-page)
- [TurboModule System](https://reactnative.dev/docs/the-new-architecture/pillars-turbomodules)
- [CustomerIO SDK Documentation](https://customer.io/docs/sdk/react-native/)