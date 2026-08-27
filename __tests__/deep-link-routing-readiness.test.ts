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
    initNativeLogger: jest.fn(),
    initialize: jest.fn(),
  },
}));
jest.mock('../src/specs/modules/NativeCustomerIO', () => ({
  __esModule: true,
  default: {
    setDeepLinkRoutingReady: jest.fn(),
  },
}));

import { CustomerIO } from '../src/customerio-cdp';
import NativeCustomerIO from '../src/specs/modules/NativeCustomerIO';

describe('CustomerIO scene deep-link readiness', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('notifies the native router after the host registers its Linking listener', () => {
    CustomerIO.setDeepLinkRoutingReady();

    expect(NativeCustomerIO.setDeepLinkRoutingReady).toHaveBeenCalledTimes(1);
  });
});
