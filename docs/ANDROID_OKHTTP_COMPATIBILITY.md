# Android OkHttp Compatibility Guide

## Issue Overview

Starting with customerio-reactnative v6.1.0, the Android SDK was upgraded to version 4.15.0+ which introduced:
- **New Feature**: In-App messaging with Server-Sent Events (SSE)
- **Dependency Change**: OkHttp upgraded from 4.x to 5.x

This creates a compatibility issue with **React Native 0.81 and earlier**, which depend on OkHttp 4.x.

## Symptoms

### Build Error
```
FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':app:mergeDebugJavaResource'.
> 3 files found with path 'META-INF/versions/9/OSGI-INF/MANIFEST.MF' from inputs:
   - com.squareup.okhttp3:logging-interceptor:5.2.1
   - com.squareup.okhttp3:okhttp-sse:5.2.1
   - org.jspecify:jspecify:1.0.0
```

### Runtime Crash
```
java.lang.NoClassDefFoundError: Failed resolution of: Lokhttp3/internal/Util;
  at okhttp3.JavaNetCookieJar.decodeHeaderAsJavaNetCookies
```

## Solutions

### Option 1: Use OkHttp 4.x Workaround (Current SDK Behavior)

The SDK automatically forces OkHttp 4.12.0 to maintain compatibility with React Native 0.81.

**Pros:**
- ✅ Builds successfully on React Native 0.81
- ✅ No runtime crashes
- ✅ All features except SSE work normally

**Cons:**
- ⚠️ In-App SSE feature may not work correctly
- ⚠️ Using older OkHttp version than intended

**How to verify:** The workaround is applied automatically in `android/build.gradle`

### Option 2: Downgrade to v6.0.0

Stay on the last version before SSE was introduced.

```bash
npm install customerio-reactnative@6.0.0
```

**Pros:**
- ✅ Stable and tested with React Native 0.81
- ✅ All features work as designed

**Cons:**
- ❌ No In-App SSE support
- ❌ Missing other improvements from v6.1.0+

### Option 3: Upgrade React Native

Upgrade to React Native 0.82+ if it supports OkHttp 5.x (verify compatibility first).

**Pros:**
- ✅ Full SSE support
- ✅ Latest SDK features
- ✅ Using intended dependency versions

**Cons:**
- ⚠️ Requires React Native upgrade (may involve breaking changes)
- ⚠️ React Native 0.82+ OkHttp version needs verification

### Option 4: Disable OkHttp 4.x Workaround

If you're using React Native 0.82+ or Expo 55+, you may be able to use OkHttp 5.x natively.

**To disable the workaround**, comment out the `configurations.all` block in your app's `android/build.gradle` or `android/app/build.gradle`:

```gradle
// Add this to your app's build.gradle to override the SDK's workaround
configurations.all {
  resolutionStrategy {
    // Allow OkHttp 5.x
    force 'com.squareup.okhttp3:okhttp:5.2.1'
    force 'com.squareup.okhttp3:logging-interceptor:5.2.1'
    force 'com.squareup.okhttp3:okhttp-sse:5.2.1'
  }
}

// Handle duplicate META-INF files
android {
  packagingOptions {
    pickFirst 'META-INF/versions/9/OSGI-INF/MANIFEST.MF'
  }
}
```

## Recommendations

| React Native Version | Recommended Solution |
|---------------------|---------------------|
| RN 0.81 or earlier | Option 1 (current behavior) or Option 2 (downgrade) |
| RN 0.82+ | Test Option 4 (disable workaround) first; fallback to Option 1 |
| Expo 54 + RN 0.81 | Option 1 (current behavior) or Option 2 (downgrade) |
| Expo 55+ | Test Option 4 (disable workaround) first |

## Testing SSE Functionality

If using Option 1 (OkHttp 4.x workaround), test In-App SSE messaging thoroughly:

1. Configure In-App messaging in your Customer.io workspace
2. Send an In-App message to a test device
3. Verify message delivery and display
4. Check logs for SSE-related errors

If SSE doesn't work, consider Option 2 (downgrade) or Option 3 (upgrade React Native).

## Related Issues

- Linear: [MBL-1544](https://linear.app/customerio/issue/MBL-1544)
- GitHub PR: [#562](https://github.com/customerio/customerio-reactnative/pull/562)

## Questions?

If you encounter issues or need help choosing the right option for your app, please [open an issue](https://github.com/customerio/customerio-reactnative/issues).
