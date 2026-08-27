jest.mock('react-native', () => ({
  TurboModuleRegistry: {
    getEnforcing: jest.fn(),
  },
}));

jest.mock('../src/specs/modules/NativeCustomerIOLiveActivities', () => ({
  __esModule: true,
  default: {
    handleWidgetUrl: jest.fn(),
  },
}));

import { CustomerIOLiveActivities } from '../src/customerio-liveactivities';
import NativeModule from '../src/specs/modules/NativeCustomerIOLiveActivities';

const native = NativeModule as unknown as {
  handleWidgetUrl: jest.Mock;
};

describe('CustomerIOLiveActivities.handleWidgetUrl', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns the destination produced by the native SDK', async () => {
    native.handleWidgetUrl.mockResolvedValue('my-app://orders/123');

    await expect(
      new CustomerIOLiveActivities().handleWidgetUrl(
        'cio-live-activity://open?cio_redirect=my-app%3A%2F%2Forders%2F123'
      )
    ).resolves.toBe('my-app://orders/123');
  });

  it('returns null when the tracking URL has no destination', async () => {
    native.handleWidgetUrl.mockResolvedValue(null);

    await expect(
      new CustomerIOLiveActivities().handleWidgetUrl(
        'cio-live-activity://open?cio_delivery_id=delivery-id'
      )
    ).resolves.toBeNull();
  });

  it('preserves an ordinary URL', async () => {
    native.handleWidgetUrl.mockResolvedValue('https://example.com');

    await expect(
      new CustomerIOLiveActivities().handleWidgetUrl('https://example.com')
    ).resolves.toBe('https://example.com');
  });

  it('preserves the input when the native bridge cannot transform it', async () => {
    native.handleWidgetUrl.mockRejectedValue(new Error('bridge unavailable'));

    await expect(
      new CustomerIOLiveActivities().handleWidgetUrl('not necessarily a URL')
    ).resolves.toBe('not necessarily a URL');
  });
});
