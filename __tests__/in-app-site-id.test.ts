/**
 * `inApp.siteId` stays required, even with a workspace public (`pk_`) key, until the native SDKs
 * and the in-app renderer support key-only setup. The JavaScript layer forwards the config as given.
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
  it('forwards the site ID with a pk_ key', async () => {
    const config: CioConfig = {
      cdpApiKey: 'pk_eu_test-key',
      inApp: { siteId: 'test-site-id' },
    };

    await CustomerIO.initialize(config);

    expect(nativeInitialize).toHaveBeenCalledWith(
      expect.objectContaining({
        cdpApiKey: 'pk_eu_test-key',
        inApp: { siteId: 'test-site-id' },
      }),
      expect.anything()
    );
  });
});
