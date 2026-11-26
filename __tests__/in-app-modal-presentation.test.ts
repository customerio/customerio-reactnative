/**
 * Covers what the JavaScript layer owns for `inApp.android.modalPresentation`: the wire values
 * Android matches against its `ModalPresentation` enum names, and the warning for a value Android
 * would ignore. The native mapping itself lives in `NativeMessagingInAppModule.kt`.
 */

jest.mock('react-native', () => ({
  Platform: {
    OS: 'android',
    select: (spec: { [key: string]: unknown }) =>
      spec.android ?? spec.default ?? undefined,
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
import { ModalPresentationAndroid, type CioConfig } from '../src/types';

const nativeInitialize = NativeModule.initialize as jest.Mock;

const configWith = (inApp: CioConfig['inApp']): CioConfig =>
  ({ cdpApiKey: 'test-key', inApp }) as CioConfig;

describe('in-app modal presentation (Android)', () => {
  let warn: jest.SpyInstance;

  beforeEach(() => {
    nativeInitialize.mockClear();
    warn = jest.spyOn(console, 'warn').mockImplementation(() => {});
  });

  afterEach(() => {
    warn.mockRestore();
  });

  it('serializes every member to the native enum name', () => {
    // Android resolves these with enumValueOf, so they must match ModalPresentation exactly.
    expect(ModalPresentationAndroid.Activity).toBe('ACTIVITY');
    expect(ModalPresentationAndroid.HostWindow).toBe('HOST_WINDOW');
  });

  it('forwards the value under inApp.android', async () => {
    await CustomerIO.initialize(
      configWith({
        android: { modalPresentation: ModalPresentationAndroid.HostWindow },
      })
    );

    expect(nativeInitialize).toHaveBeenCalledWith(
      expect.objectContaining({
        inApp: { android: { modalPresentation: 'HOST_WINDOW' } },
      }),
      expect.anything()
    );
    expect(warn).not.toHaveBeenCalled();
  });

  it('stays quiet when the option is left out', async () => {
    await CustomerIO.initialize(configWith({ android: {} }));

    expect(warn).not.toHaveBeenCalled();
  });

  it('warns when the value is not a ModalPresentationAndroid', async () => {
    await CustomerIO.initialize(
      configWith({
        android: {
          modalPresentation:
            'host_window' as unknown as ModalPresentationAndroid,
        },
      })
    );

    expect(warn).toHaveBeenCalledWith(
      expect.stringContaining('"inApp.android.modalPresentation"')
    );
  });
});
