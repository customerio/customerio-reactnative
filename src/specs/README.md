# CustomerIO React Native SDK - TurboModule Specifications

This directory contains the TypeScript specifications for the CustomerIO React Native SDK. These specifications define the interface between JavaScript and native code following React Native's New Architecture patterns.

## Overview

React Native's New Architecture introduces TurboModules, which provide a more efficient and type-safe way to bridge JavaScript and native code. The specifications in this directory define the interface for the CustomerIO SDK's native modules.

The specifications are organized into three main modules:

1. **CustomerIOModuleSpec**: Core CDP functionality (identify, track, etc.)
2. **InAppMessagingModuleSpec**: In-app messaging functionality
3. **PushMessagingModuleSpec**: Push messaging functionality

## TypeScript Specifications

The TypeScript specifications provide type safety and documentation for the interface between JavaScript and native code. They are organized as follows:

- `CustomerIOTypes.ts`: Common types and enums used across the SDK
- `CustomerIOModuleSpec.ts`: Specification for the core CDP functionality
- `InAppMessagingModuleSpec.ts`: Specification for in-app messaging
- `PushMessagingModuleSpec.ts`: Specification for push messaging
- `index.ts`: Exports all specifications

## Implementation Guide

### 1. JavaScript/TypeScript Side

The specifications in this directory define the interface that your JavaScript/TypeScript code will use to interact with the native modules. You can import and use these modules in your JavaScript/TypeScript code as follows:

```typescript
import { CustomerIOModuleSpec, CioConfig } from 'customerio-reactnative/lib/module/specs';

// Get the native module
const CustomerIO = TurboModuleRegistry.getEnforcing<CustomerIOModuleSpec>('NativeCustomerIO');

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

// Track an event
CustomerIO.track('event-name', {
  // event properties
});
```

### 2. Native Side Implementation (iOS)

For iOS, you'll need to implement the native module in Objective-C or Swift. Here's a basic outline of how to implement the CustomerIO TurboModule in Swift:

1. Create a new Swift file `CustomerIOTurboModule.swift` in the `ios` directory:

```swift
import CioAnalytics
import CioDataPipelines
import CioInternalCommon
import CioMessagingInApp
import CioMessagingPush
import React

@objc(CustomerIOTurboModule)
class CustomerIOTurboModule: NSObject {
  
  @objc
  func initialize(_ config: NSDictionary, packageInfo: NSDictionary) {
    // Implementation
  }
  
  @objc
  func identify(_ userId: String?, traits: NSDictionary?) {
    // Implementation
  }
  
  @objc
  func track(_ name: String, properties: NSDictionary?) {
    // Implementation
  }
  
  // Implement other methods defined in the specification
}
```

2. Create a corresponding Objective-C header file to expose the module to React Native:

```objc
#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(CustomerIOTurboModule, NSObject)

RCT_EXTERN_METHOD(initialize:(NSDictionary *)config
                  packageInfo:(NSDictionary *)packageInfo)

RCT_EXTERN_METHOD(identify:(NSString *)userId
                  traits:(NSDictionary *)traits)

RCT_EXTERN_METHOD(track:(NSString *)name
                  properties:(NSDictionary *)properties)

// Declare other methods defined in the specification

@end
```

### 3. Native Side Implementation (Android)

For Android, you'll need to implement the native module in Kotlin or Java. Here's a basic outline of how to implement the CustomerIO TurboModule in Kotlin:

1. Create a new Kotlin file `CustomerIOTurboModule.kt` in the `android/src/main/java/io/customer/reactnative/sdk` directory:

```kotlin
package io.customer.reactnative.sdk

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import io.customer.sdk.CustomerIO

class CustomerIOTurboModule(
  reactContext: ReactApplicationContext
) : ReactContextBaseJavaModule(reactContext) {
  
  override fun getName(): String = "CustomerIOTurboModule"
  
  @ReactMethod
  fun initialize(config: ReadableMap, packageInfo: ReadableMap) {
    // Implementation
  }
  
  @ReactMethod
  fun identify(userId: String?, traits: ReadableMap?) {
    // Implementation
  }
  
  @ReactMethod
  fun track(name: String, properties: ReadableMap?) {
    // Implementation
  }
  
  // Implement other methods defined in the specification
}
```

2. Register the module in the package class:

```kotlin
package io.customer.reactnative.sdk

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager

class CustomerIOReactNativePackage : ReactPackage {
  override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
    return listOf(
      CustomerIOTurboModule(reactContext),
      // Other modules
    )
  }

  override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
    return emptyList()
  }
}
```

## Type Safety Benefits

The TypeScript specifications provide several benefits:

1. **Compile-time Type Checking**: Catch errors at compile time rather than runtime
2. **Code Completion**: Get code completion in your IDE for the SDK's API
3. **Documentation**: The specifications serve as documentation for the SDK's API
4. **Refactoring Support**: Easily refactor code that uses the SDK

## Best Practices

1. **Error Handling**: Always handle errors gracefully in your native implementations and provide meaningful error messages to JavaScript.
2. **Async Operations**: Use promises for asynchronous operations to provide a better developer experience.
3. **Type Safety**: Leverage the type safety provided by the specifications to catch errors early.
4. **Documentation**: Keep the specifications and implementations well-documented to make it easier for other developers to understand and use your code.

## Resources

- [React Native New Architecture Documentation](https://reactnative.dev/docs/the-new-architecture/landing-page)
- [TurboModule System](https://reactnative.dev/docs/the-new-architecture/pillars-turbomodules)
- [CustomerIO SDK Documentation](https://customer.io/docs/sdk/react-native/)