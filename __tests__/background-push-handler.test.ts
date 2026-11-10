// Platform.OS and the registered headless tasks live in mocks the tests can read and change.
const mockPlatform = {
  OS: 'ios' as 'ios' | 'android',
  select: (spec: { [key: string]: unknown }) => spec.default,
};
const mockHeadlessTasks = new Map<
  string,
  () => (data: unknown) => Promise<void>
>();

jest.mock('react-native', () => ({
  Platform: mockPlatform,
  AppRegistry: {
    registerHeadlessTask: jest.fn(
      (key: string, provider: () => (data: unknown) => Promise<void>) => {
        mockHeadlessTasks.set(key, provider);
      }
    ),
  },
}));
jest.mock('../src/native-logger-listener', () => ({
  NativeLoggerListener: { warn: jest.fn() },
}));
jest.mock('../src/specs/modules/NativeCustomerIOMessagingPush', () => {
  const nativeModule = {
    registerBackgroundPushHandler: jest.fn(),
    unregisterBackgroundPushHandler: jest.fn(),
    acknowledgeBackgroundPush: jest.fn(),
    onBackgroundPushReceived: jest.fn((listener) => {
      nativeModule.emit = listener;
      return { remove: jest.fn() };
    }),
    emit: undefined as unknown,
  };
  return { __esModule: true, default: nativeModule };
});

type NativeMock = {
  registerBackgroundPushHandler: jest.Mock;
  unregisterBackgroundPushHandler: jest.Mock;
  acknowledgeBackgroundPush: jest.Mock;
  onBackgroundPushReceived: jest.Mock;
  emit?: (event: unknown) => Promise<void>;
};

const push = {
  deliveryId: 'delivery-1',
  deliveryToken: 'token-1',
  data: { account: 'refresh' },
};
const event = { id: 'push-1', push };

// The handler is module state, so each test loads a fresh copy of the module.
const load = () => {
  let loaded!: {
    pushMessaging: import('../src/customerio-push').CustomerIOPushMessaging;
    native: NativeMock;
    warn: jest.Mock;
    registerHeadlessTask: jest.Mock;
  };
  jest.isolateModules(() => {
    const { CustomerIOPushMessaging } = require('../src/customerio-push');
    loaded = {
      pushMessaging: new CustomerIOPushMessaging(),
      native: require('../src/specs/modules/NativeCustomerIOMessagingPush')
        .default,
      warn: require('../src/native-logger-listener').NativeLoggerListener.warn,
      registerHeadlessTask:
        require('react-native').AppRegistry.registerHeadlessTask,
    };
  });
  return loaded;
};

const runTask = (data: unknown) =>
  mockHeadlessTasks.get('CustomerIOBackgroundPush')!()(data);

beforeEach(() => {
  jest.clearAllMocks();
  mockHeadlessTasks.clear();
});

describe('setBackgroundPushHandler on Android', () => {
  beforeEach(() => {
    mockPlatform.OS = 'android';
  });

  it('registers the Headless JS task once, before telling native', () => {
    const { pushMessaging, native, registerHeadlessTask } = load();

    pushMessaging.setBackgroundPushHandler(jest.fn());
    pushMessaging.setBackgroundPushHandler(jest.fn());

    expect(registerHeadlessTask).toHaveBeenCalledTimes(1);
    expect(registerHeadlessTask.mock.invocationCallOrder[0]).toBeLessThan(
      native.registerBackgroundPushHandler.mock.invocationCallOrder[0]!
    );
    expect(native.registerBackgroundPushHandler).toHaveBeenCalledTimes(2);
    expect(native.onBackgroundPushReceived).not.toHaveBeenCalled();
  });

  it('runs the handler, then acknowledges the push', async () => {
    const { pushMessaging, native } = load();
    const handler = jest.fn(async () => {
      expect(native.acknowledgeBackgroundPush).not.toHaveBeenCalled();
    });
    pushMessaging.setBackgroundPushHandler(handler);

    await runTask(event);

    expect(handler).toHaveBeenCalledWith(push);
    expect(native.acknowledgeBackgroundPush).toHaveBeenCalledWith('push-1');
  });

  it('acknowledges a push whose handler throws', async () => {
    const { pushMessaging, native, warn } = load();
    pushMessaging.setBackgroundPushHandler(async () => {
      throw new Error('boom');
    });

    await expect(runTask(event)).resolves.toBeUndefined();

    expect(warn).toHaveBeenCalled();
    expect(native.acknowledgeBackgroundPush).toHaveBeenCalledWith('push-1');
  });

  it('stops calling a removed handler but still acknowledges', async () => {
    const { pushMessaging, native } = load();
    const handler = jest.fn();
    pushMessaging.setBackgroundPushHandler(handler).remove();

    await runTask(event);

    expect(native.unregisterBackgroundPushHandler).toHaveBeenCalledTimes(1);
    expect(handler).not.toHaveBeenCalled();
    expect(native.acknowledgeBackgroundPush).toHaveBeenCalledWith('push-1');
  });

  it('keeps a replacement when the old subscription is removed', async () => {
    const { pushMessaging, native } = load();
    // The same function twice, so only the subscription tells them apart.
    const handler = jest.fn();
    const first = pushMessaging.setBackgroundPushHandler(handler);
    pushMessaging.setBackgroundPushHandler(handler);

    first.remove();
    await runTask(event);

    expect(native.unregisterBackgroundPushHandler).not.toHaveBeenCalled();
    expect(handler).toHaveBeenCalledWith(push);
  });
});

describe('setBackgroundPushHandler on iOS', () => {
  beforeEach(() => {
    mockPlatform.OS = 'ios';
  });

  it('listens for native events before telling native', () => {
    const { pushMessaging, native } = load();

    pushMessaging.setBackgroundPushHandler(jest.fn());

    expect(
      native.onBackgroundPushReceived.mock.invocationCallOrder[0]
    ).toBeLessThan(
      native.registerBackgroundPushHandler.mock.invocationCallOrder[0]!
    );
    expect(mockHeadlessTasks.size).toBe(0);
  });

  it('runs the handler for a native event, then acknowledges it', async () => {
    const { pushMessaging, native } = load();
    const handler = jest.fn();
    pushMessaging.setBackgroundPushHandler(handler);

    await native.emit!(event);

    expect(handler).toHaveBeenCalledWith(push);
    expect(native.acknowledgeBackgroundPush).toHaveBeenCalledWith('push-1');
  });
});
