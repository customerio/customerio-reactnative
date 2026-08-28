jest.mock('react-native', () => ({
  Platform: {
    OS: 'ios',
    select: (spec: { [key: string]: unknown }) =>
      spec.ios ?? spec.default ?? undefined,
  },
}));

jest.mock('../src/customerio-geofence', () => ({
  CustomerIOGeofence: class {},
}));
jest.mock('../src/customerio-inapp', () => ({
  CustomerIOInAppMessaging: class {},
}));
jest.mock('../src/customerio-liveactivities', () => ({
  CustomerIOLiveActivities: class {},
}));
jest.mock('../src/customerio-location', () => ({
  CustomerIOLocation: class {},
}));
jest.mock('../src/customerio-push', () => ({
  CustomerIOPushMessaging: class {},
}));
jest.mock('../src/native-logger-listener', () => ({
  NativeLoggerListener: {
    initialize: jest.fn(),
    initNativeLogger: jest.fn(),
    warn: jest.fn(),
  },
}));
jest.mock('../src/specs/modules/NativeCustomerIO', () => {
  const nativeModule = {
    setDeepLinkRoutingReady: jest.fn(),
    registerDeepLinkHandler: jest.fn(),
    unregisterDeepLinkHandler: jest.fn(),
    acknowledgeDeepLink: jest.fn(),
    onDeepLinkReceived: jest.fn((emitter) => {
      nativeModule.__emit = emitter;
      return { remove: nativeModule.__nativeRemove };
    }),
    __emit: undefined,
    __nativeRemove: jest.fn(),
  };
  return { __esModule: true, default: nativeModule };
});

import {
  CustomerIO,
  type DeepLinkHandlerSubscription,
} from '../src/customerio-cdp';
import { NativeLoggerListener } from '../src/native-logger-listener';
import NativeCustomerIO from '../src/specs/modules/NativeCustomerIO';

const native = NativeCustomerIO as unknown as {
  setDeepLinkRoutingReady: jest.Mock;
  registerDeepLinkHandler: jest.Mock;
  unregisterDeepLinkHandler: jest.Mock;
  acknowledgeDeepLink: jest.Mock;
  onDeepLinkReceived: jest.Mock;
  __nativeRemove: jest.Mock;
  __emit?: (data: unknown) => Promise<void>;
};

describe('CustomerIO scene deep-link routing', () => {
  let subscription: DeepLinkHandlerSubscription | undefined;

  beforeEach(() => {
    jest.clearAllMocks();
    native.__emit = undefined;
    subscription = undefined;
  });

  afterEach(() => {
    subscription?.remove();
  });

  it('keeps the existing Linking readiness API', () => {
    CustomerIO.setDeepLinkRoutingReady();

    expect(native.setDeepLinkRoutingReady).toHaveBeenCalledTimes(1);
  });

  it('subscribes before telling native that the handler is ready', () => {
    subscription = CustomerIO.setDeepLinkHandler(() => true);

    expect(native.onDeepLinkReceived).toHaveBeenCalledTimes(1);
    expect(native.registerDeepLinkHandler).toHaveBeenCalledTimes(1);
    expect(native.onDeepLinkReceived.mock.invocationCallOrder[0]).toBeLessThan(
      native.registerDeepLinkHandler.mock.invocationCallOrder[0]
    );
  });

  it('acknowledges a handled URL', async () => {
    const handler = jest.fn().mockResolvedValue(true);
    subscription = CustomerIO.setDeepLinkHandler(handler);

    await native.__emit?.({ id: 'request-1', url: 'myapp://inbox' });

    expect(handler).toHaveBeenCalledWith('myapp://inbox');
    expect(native.acknowledgeDeepLink).toHaveBeenCalledWith('request-1', true);
  });

  it('declines a URL when the handler returns false', async () => {
    subscription = CustomerIO.setDeepLinkHandler(() => false);

    await native.__emit?.({ id: 'request-2', url: 'https://example.com' });

    expect(native.acknowledgeDeepLink).toHaveBeenCalledWith('request-2', false);
  });

  it('declines a URL when the handler fails', async () => {
    const error = new Error('route failed');
    subscription = CustomerIO.setDeepLinkHandler(() => Promise.reject(error));

    await native.__emit?.({ id: 'request-3', url: 'myapp://settings' });

    expect(NativeLoggerListener.warn).toHaveBeenCalledWith(
      'Deep-link handler failed:',
      error
    );
    expect(native.acknowledgeDeepLink).toHaveBeenCalledWith('request-3', false);
  });

  it('leaves malformed native events for the native timeout fallback', async () => {
    subscription = CustomerIO.setDeepLinkHandler(() => true);

    await native.__emit?.({ id: 'request-4' });

    expect(NativeLoggerListener.warn).toHaveBeenCalledWith(
      'Received an invalid native deep-link event.'
    );
    expect(native.acknowledgeDeepLink).not.toHaveBeenCalled();
  });

  it('unregisters native routing when the subscription is removed', () => {
    subscription = CustomerIO.setDeepLinkHandler(() => true);

    subscription.remove();
    subscription.remove();

    expect(native.unregisterDeepLinkHandler).toHaveBeenCalledTimes(1);
    expect(native.__nativeRemove).toHaveBeenCalledTimes(1);
    subscription = undefined;
  });

  it('unregisters the previous handler before replacing it', () => {
    CustomerIO.setDeepLinkHandler(() => true);

    subscription = CustomerIO.setDeepLinkHandler(() => false);

    expect(native.unregisterDeepLinkHandler).toHaveBeenCalledTimes(1);
    expect(native.__nativeRemove).toHaveBeenCalledTimes(1);
    expect(native.registerDeepLinkHandler).toHaveBeenCalledTimes(2);
  });

  it('rejects a non-function handler', () => {
    expect(() => CustomerIO.setDeepLinkHandler(null as never)).toThrow(
      '[CustomerIO] "handler" must be a function.'
    );
  });
});
