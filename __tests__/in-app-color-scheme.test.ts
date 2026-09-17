/**
 * Verifies the in-app color scheme override survives the JS -> native hop, by both routes it can
 * travel: once through `initialize`, and again through the runtime setter.
 *
 * The native SDKs do the real work — each resolves the scheme and re-themes messages already on
 * screen, inline views included. What only JavaScript can get wrong is the wire value: both
 * native layers match `auto`/`light`/`dark` lowercase, and iOS's config parser resolves anything
 * else to `.auto`, so a re-cased or renamed value would silently render the device's theme
 * instead of the one the app asked for. That is a styling bug with no error attached, which is
 * why the serialized values are pinned here.
 *
 * Scope: the JavaScript half only. These do NOT pin the native key name — renaming `colorScheme`
 * in either bridge leaves them green while the override stops arriving.
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

jest.mock('../src/specs/modules/NativeCustomerIOMessagingInApp', () => ({
  __esModule: true,
  default: { setColorScheme: jest.fn() },
}));

import { CustomerIO } from '../src/customerio-cdp';
import NativeModule from '../src/specs/modules/NativeCustomerIO';
import NativeInAppModule from '../src/specs/modules/NativeCustomerIOMessagingInApp';
import { CioColorScheme, type CioConfig } from '../src/types';

const nativeInitialize = NativeModule.initialize as jest.Mock;
const nativeSetColorScheme = NativeInAppModule.setColorScheme as jest.Mock;

const configWith = (inApp: CioConfig['inApp']): CioConfig =>
  ({ cdpApiKey: 'test-key', inApp }) as CioConfig;

const forwardedInApp = () => nativeInitialize.mock.calls[0][0].inApp;

describe('in-app color scheme', () => {
  beforeEach(() => {
    nativeInitialize.mockClear();
    nativeSetColorScheme.mockClear();
  });

  describe('wire values', () => {
    // Both native layers match these lowercase and treat anything else as `auto`. Renaming a
    // member is safe; changing one of these strings silently breaks the override on both
    // platforms, so they are asserted literally rather than through the enum.
    it('serializes every member to the value both native SDKs match', () => {
      expect(CioColorScheme.Auto).toBe('auto');
      expect(CioColorScheme.Light).toBe('light');
      expect(CioColorScheme.Dark).toBe('dark');
    });
  });

  describe('initialize', () => {
    it('forwards the configured scheme under the key the native parsers read', async () => {
      await CustomerIO.initialize(
        configWith({ siteId: 'site', colorScheme: CioColorScheme.Dark })
      );

      expect(forwardedInApp().colorScheme).toBe('dark');
    });

    it('omits the scheme when the app configures none', async () => {
      await CustomerIO.initialize(configWith({ siteId: 'site' }));

      // Absent rather than 'auto': the native default is already AUTO, and the JS layer should
      // not manufacture a value the host never set.
      expect(forwardedInApp().colorScheme).toBeUndefined();
    });
  });

  describe('setColorScheme', () => {
    it('sends the scheme to the native module as its wire value', () => {
      CustomerIO.inAppMessaging.setColorScheme(CioColorScheme.Light);

      expect(nativeSetColorScheme).toHaveBeenCalledWith('light');
    });

    it('can return to following the device appearance', () => {
      CustomerIO.inAppMessaging.setColorScheme(CioColorScheme.Auto);

      expect(nativeSetColorScheme).toHaveBeenCalledWith('auto');
    });
  });

  // TypeScript rejects a bad value, but JavaScript callers reach this untyped. Neither native
  // layer can report it usefully, so the warning is raised here.
  describe('invalid value warning', () => {
    let warn: jest.SpyInstance;

    beforeEach(() => {
      warn = jest.spyOn(console, 'warn').mockImplementation(() => {});
    });

    afterEach(() => {
      warn.mockRestore();
    });

    it('warns when the value is not a CioColorScheme', async () => {
      await CustomerIO.initialize(
        configWith({
          siteId: 'site',
          colorScheme: 'DARK' as unknown as CioColorScheme,
        })
      );

      expect(warn).toHaveBeenCalledWith(
        expect.stringContaining('"inApp.colorScheme"')
      );
    });

    it('still forwards the value, leaving the native fallback to decide', async () => {
      await CustomerIO.initialize(
        configWith({
          siteId: 'site',
          colorScheme: 'DARK' as unknown as CioColorScheme,
        })
      );

      // Warn, do not sanitize: dropping the key here would make the JS layer's opinion
      // indistinguishable from the host omitting it.
      expect(forwardedInApp().colorScheme).toBe('DARK');
    });

    it('stays quiet for a valid scheme', async () => {
      await CustomerIO.initialize(
        configWith({ siteId: 'site', colorScheme: CioColorScheme.Dark })
      );

      expect(warn).not.toHaveBeenCalled();
    });
  });
});
