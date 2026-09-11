/**
 * Verifies the Visual Notification Inbox accessibility labels survive the JS -> native hop.
 *
 * The labels are plain data on `CioConfig['inApp']`, and the native side does the real work: iOS
 * parses the dictionary in `MessagingInAppConfigBuilder.build(from:)`, Android converts the
 * `{count}` template into the `(Int) -> String` the SDK expects. What JavaScript owns is the
 * contract — the labels must reach `native.initialize` intact, under exactly the keys the native
 * parsers look for. A rename on either side silently drops every label (the SDK emits no text of
 * its own, so the UI would simply go unlabeled rather than fail), which is what this locks down.
 *
 * `jest.mock` factories are hoisted above module-scope declarations, so each mock is created
 * inside its factory and read back from the imported (mocked) module.
 */

// Importing `customerio-cdp` pulls in every sibling module, and each one resolves its TurboModule
// at import time — so the mock needs TurboModuleRegistry as well as Platform.
jest.mock('react-native', () => ({
  Platform: {
    OS: 'ios',
    select: (spec: { [key: string]: unknown }) =>
      spec.ios ?? spec.default ?? undefined,
  },
  TurboModuleRegistry: {
    get: jest.fn(() => null),
    getEnforcing: jest.fn(() => ({})),
  },
  NativeEventEmitter: jest.fn(() => ({
    addListener: jest.fn(() => ({ remove: jest.fn() })),
  })),
}));

// The native Fabric components pull in codegen internals this test does not need.
jest.mock('../src/components', () => ({}));

jest.mock('../src/native-logger-listener', () => ({
  NativeLoggerListener: {
    warn: jest.fn(),
    initialize: jest.fn(),
    // customerio-cdp calls this at module scope.
    initNativeLogger: jest.fn(),
  },
}));

jest.mock('../src/specs/modules/NativeCustomerIO', () => ({
  __esModule: true,
  default: { initialize: jest.fn(() => Promise.resolve(true)) },
}));

import { CustomerIO } from '../src/customerio-cdp';
import NativeModule from '../src/specs/modules/NativeCustomerIO';
import type { CioConfig } from '../src/types';

const nativeInitialize = NativeModule.initialize as jest.Mock;

const labels = {
  bell: 'Aviseringar',
  bellWithUnreadCount: 'Aviseringar, {count} olasta',
  loadingIndicator: 'Laddar',
  emptyState: 'Inga aviseringar',
};

const configWith = (inApp: CioConfig['inApp']): CioConfig =>
  ({ cdpApiKey: 'test-key', inApp }) as CioConfig;

describe('notification inbox accessibility labels', () => {
  beforeEach(() => {
    nativeInitialize.mockClear();
  });

  it('forwards every label to the native module under the shared config key', async () => {
    await CustomerIO.initialize(
      configWith({
        siteId: 'site',
        notificationInboxAccessibilityLabels: labels,
      })
    );

    const [forwardedConfig] = nativeInitialize.mock.calls[0];
    expect(forwardedConfig.inApp.notificationInboxAccessibilityLabels).toEqual(
      labels
    );
  });

  it('keeps the {count} placeholder intact for the native side to substitute', async () => {
    await CustomerIO.initialize(
      configWith({
        siteId: 'site',
        notificationInboxAccessibilityLabels: labels,
      })
    );

    const [forwardedConfig] = nativeInitialize.mock.calls[0];
    // JS must not interpolate: the count is only known natively, at render time.
    expect(
      forwardedConfig.inApp.notificationInboxAccessibilityLabels
        .bellWithUnreadCount
    ).toContain('{count}');
  });

  it('omits the labels entirely when the app configures none', async () => {
    await CustomerIO.initialize(configWith({ siteId: 'site' }));

    const [forwardedConfig] = nativeInitialize.mock.calls[0];
    // Absent rather than an empty object: the native default is "emit no labels at all",
    // and nothing in the JS layer should manufacture a value the host did not set.
    expect(
      forwardedConfig.inApp.notificationInboxAccessibilityLabels
    ).toBeUndefined();
  });

  it('forwards a partial set without filling in the rest', async () => {
    await CustomerIO.initialize(
      configWith({
        siteId: 'site',
        notificationInboxAccessibilityLabels: {
          emptyState: 'Inga aviseringar',
        },
      })
    );

    const [forwardedConfig] = nativeInitialize.mock.calls[0];
    expect(forwardedConfig.inApp.notificationInboxAccessibilityLabels).toEqual({
      emptyState: 'Inga aviseringar',
    });
  });
});
