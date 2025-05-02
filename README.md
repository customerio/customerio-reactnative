<p align="center">
  <a href="https://customer.io">
    <img src="https://avatars.githubusercontent.com/u/1152079?s=200&v=4" height="60">
  </a>
</p>

[![npm version](https://img.shields.io/npm/v/customerio-reactnative.svg)](https://www.npmjs.com/package/customerio-reactnative)
[![npm downloads](https://img.shields.io/npm/dm/customerio-reactnative)](https://www.npmjs.com/package/customerio-reactnative)
![min Android SDK version is 21](https://img.shields.io/badge/min%20Android%20SDK-21-green)
![min iOS version is 13](https://img.shields.io/badge/min%20iOS%20version-13-blue)
![min Swift version is 5.3](https://img.shields.io/badge/min%20Swift%20version-5.3-orange)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.0-4baaaa.svg)](CODE_OF_CONDUCT.md)

# Customer.io React Native SDK

The official Customer.io SDK for React Native enables you to integrate mobile messaging features—like in-app messaging and push notifications—into your app. These features can be triggered by events sent through the SDK and configured using your Customer.io campaigns.

> 📖 Full documentation: [customer.io/docs/sdk/react-native](https://customer.io/docs/sdk/react-native/)  
> 🧪 Example apps: [see the `/example` directory](/example)

---

## Installation

```bash
npm install customerio-reactnative
```

---

## SDK Initialization

Here’s a simplified example showing how to initialize the SDK to enable most mobile features:

```ts
import {
  CustomerIO,
  CioConfig,
  CioLogLevel,
  CioRegion,
} from 'customerio-reactnative';

useEffect(() => {
  const config: CioConfig = {
    cdpApiKey: 'your-cdp-api-key', // Required
    migrationSiteId: 'your-site-id', // Optional, for migrating from older SDKs
    region: CioRegion.US, // Or CioRegion.EU
    logLevel: CioLogLevel.debug,
    trackApplicationLifecycleEvents: true,
    inApp: {
      siteId: 'your-site-id', // Required for in-app messaging
    },
    push: {
      android: {
        pushClickBehavior: 'ActivityPreventRestart', // Optional
      },
    },
  };

  CustomerIO.initialize(config);
}, []);
```

> 🔑 For help finding your credentials, check out the [Quick Start Guide](https://customer.io/docs/sdk/react-native/quick-start-guide/#step-1).

---

## 📲 Push Notifications

This SDK supports [rich push notifications](https://customer.io/docs/sdk/react-native/rich-push/) using Firebase (for Android) and either Firebase or APNs (for iOS). Follow our [push setup guide](https://customer.io/docs/sdk/react-native/push/) to configure your project for push.

---

## Identify Users, Track Events, and More

Customer.io helps you personalize your mobile experience:

- 👤 [Identify users](https://customer.io/docs/sdk/react-native/identify/) to associate events and devices with profiles
- 📊 [Track events](https://customer.io/docs/sdk/react-native/track-events/) to trigger messaging based on user behavior
- 💬 [In-App Messages](https://customer.io/docs/sdk/react-native/in-app/) are server-driven and blend seamlessly with your app

---

## Contributing

We welcome contributions! To get started:

1. Review our [example app](/example) to help with local development.
2. Follow our [Code of Conduct](CODE_OF_CONDUCT.md).

---

## License

[MIT](LICENSE)
