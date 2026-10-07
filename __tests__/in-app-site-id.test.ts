/**
 * `inApp.siteId` is optional: a workspace public (`wk_`) key carries enough for the native SDKs
 * to resolve in-app messaging on their own. The JavaScript layer must accept an `inApp` config
 * without it and forward the config to native as given.
 */

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

jest.mock('../src/components', () => ({}));

jest.mock('../src/native-logger-listener', () => ({
  NativeLoggerListener: {
    warn: jest.fn(),
    initialize: jest.fn(),
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

describe('in-app site ID', () => {
  it('accepts an in-app config without a site ID', async () => {
    const config: CioConfig = { cdpApiKey: 'wk_test-key', inApp: {} };

    await CustomerIO.initialize(config);

    expect(nativeInitialize).toHaveBeenCalledWith(
      expect.objectContaining({ inApp: {} }),
      expect.anything()
    );
  });
});
