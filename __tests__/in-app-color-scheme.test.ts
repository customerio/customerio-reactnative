/**
 * Covers the two things the JavaScript layer actually owns for the in-app color scheme override:
 * the wire value, and the runtime setter reaching the native module.
 *
 * The native SDKs do the real work — each resolves the scheme and re-themes messages already on
 * screen, inline views included. What only JavaScript can get wrong is the wire value: both
 * native layers match `auto`/`light`/`dark` lowercase, and iOS's config parser resolves anything
 * else to `.auto`, so a re-cased or renamed value would silently render the device's theme
 * instead of the one the app asked for. That is a styling bug with no error attached, which is
 * why the serialized values are pinned here.
 *
 * Deliberately NOT covered: the `initialize` path. `CustomerIO.initialize` forwards the config
 * object verbatim, so asserting `colorScheme` on the forwarded payload only re-reads the literal
 * the test itself built — it would stay green if the Android config key or either native mapper
 * broke. The integration points that can actually break are `Keys.Config.COLOR_SCHEME` and
 * `colorSchemeFromRawValue` on Android and `colorScheme(fromRawValue:)` on iOS; guarding those
 * needs a test on the native side of each bridge, which this package has no harness for.
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

  describe('setColorScheme', () => {
    it('sends the scheme to the native module as its wire value', () => {
      CustomerIO.inAppMessaging.setColorScheme(CioColorScheme.Light);

      expect(nativeSetColorScheme).toHaveBeenCalledWith('light');
    });

    it('can return to following the device appearance', () => {
      CustomerIO.inAppMessaging.setColorScheme(CioColorScheme.Auto);

      expect(nativeSetColorScheme).toHaveBeenCalledWith('auto');
    });

    // The setter is public and reachable from untyped JavaScript, so it validates too. Its
    // fallback differs from the config path's — native leaves the current scheme in place
    // rather than dropping to `auto` — so the warning has to say something different.
    describe('invalid argument', () => {
      let warn: jest.SpyInstance;

      beforeEach(() => {
        warn = jest.spyOn(console, 'warn').mockImplementation(() => {});
      });

      afterEach(() => {
        warn.mockRestore();
      });

      it('warns and says the scheme is left unchanged', () => {
        CustomerIO.inAppMessaging.setColorScheme(
          'DARK' as unknown as CioColorScheme
        );

        expect(warn).toHaveBeenCalledWith(
          expect.stringContaining('left unchanged')
        );
      });

      it('warns when no scheme is given at all', () => {
        // Absent is the mistake here, unlike in the config, where it just means "use the
        // native default" — so null must not be skipped the way the config path skips it.
        CustomerIO.inAppMessaging.setColorScheme(
          null as unknown as CioColorScheme
        );

        expect(warn).toHaveBeenCalledWith(
          expect.stringContaining('"colorScheme"')
        );
      });

      it('stays quiet for a valid scheme', () => {
        CustomerIO.inAppMessaging.setColorScheme(CioColorScheme.Dark);

        expect(warn).not.toHaveBeenCalled();
      });
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

    it('stays quiet for a valid scheme', async () => {
      await CustomerIO.initialize(
        configWith({ siteId: 'site', colorScheme: CioColorScheme.Dark })
      );

      expect(warn).not.toHaveBeenCalled();
    });
  });
});
