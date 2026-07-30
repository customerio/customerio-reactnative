/**
 * Unit tests for the React Native Visual Notification Inbox event listener bridge.
 *
 * Mirrors the intent of the Flutter SDK's `inbox_event_listener_test.dart`:
 *   - registering wires the native forwarder + subscribes to the event emitter
 *   - native inbox events are mapped to `InboxMessageEvent` and delivered to the JS listener
 *   - `messageActionTaken` carries actionName/actionValue and the message is parsed
 *   - unregistering (subscription.remove()) tears down the native forwarder and stops delivery
 *
 * Note: `jest.mock` factories are hoisted above module-scope declarations, so every
 * mock (including the fake native module) is created inside its factory and read back
 * from the imported (mocked) module rather than closing over outer variables.
 */

// Minimal react-native mock so importing the SDK modules does not touch the
// native runtime. Only the surface used at import time is provided.
jest.mock('react-native', () => ({
  Platform: {
    OS: 'ios',
    select: (spec: { [key: string]: unknown }) =>
      spec.ios ?? spec.default ?? undefined,
  },
}));

// The native Fabric components pull in codegen internals we don't need here.
jest.mock('../src/components', () => ({}));

// Silence the native logger listener used inside the try/catch fallbacks so a
// real failure surfaces as a failing assertion rather than a swallowed warning.
jest.mock('../src/native-logger-listener', () => ({
  NativeLoggerListener: { warn: jest.fn(), initialize: jest.fn() },
}));

// Fake native TurboModule. Everything is created inside the factory (jest hoists
// this above the imports/consts below). The emitter passed to
// `onInboxEventReceived` is stored on the module so the test can simulate a
// native -> JS event by invoking `__emit`.
jest.mock('../src/specs/modules/NativeCustomerIOMessagingInApp', () => {
  const nativeModule = {
    registerInboxEventListener: jest.fn(),
    unregisterInboxEventListener: jest.fn(),
    onInboxEventReceived: jest.fn((emitter) => {
      nativeModule.__emit = emitter;
      return { remove: nativeModule.__nativeRemove };
    }),
    __emit: undefined,
    __nativeRemove: jest.fn(),
  };
  return { __esModule: true, default: nativeModule };
});

import { CustomerIOInAppMessaging } from '../src/customerio-inapp';
import NativeMock from '../src/specs/modules/NativeCustomerIOMessagingInApp';
import { InboxEventType, InboxMessageEvent } from '../src/types';

// Typed handle to the mock's extra test hooks.
const native = NativeMock as unknown as {
  registerInboxEventListener: jest.Mock;
  unregisterInboxEventListener: jest.Mock;
  onInboxEventReceived: jest.Mock;
  __nativeRemove: jest.Mock;
  __emit?: (data: unknown) => void;
};

// Serialized inbox message matching the native `toWritableMap`/`toDictionary` shape.
const rawMessage = {
  queueId: 'queue-123',
  deliveryId: 'delivery-456',
  expiry: 1710000000000,
  sentAt: 1700000000000,
  topics: ['promo', 'news'],
  type: 'inbox',
  opened: false,
  priority: 1,
  properties: { foo: 'bar' },
};

describe('CustomerIOInAppMessaging inbox event listener bridge', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    native.__emit = undefined;
  });

  it('registers the native forwarder and subscribes to the emitter', () => {
    const inApp = new CustomerIOInAppMessaging();
    inApp.registerInboxEventListener(() => {});

    expect(native.registerInboxEventListener).toHaveBeenCalledTimes(1);
    expect(native.onInboxEventReceived).toHaveBeenCalledTimes(1);
    expect(native.__emit).toBeDefined();
  });

  it('maps messageActionTaken to a parsed InboxMessageEvent with action data', () => {
    const inApp = new CustomerIOInAppMessaging();
    const received: InboxMessageEvent[] = [];
    inApp.registerInboxEventListener((event) => received.push(event));

    native.__emit?.({
      eventType: 'messageActionTaken',
      message: rawMessage,
      actionName: 'messageAction',
      actionValue: 'https://example.com',
    });

    expect(received).toHaveLength(1);
    const event = received[0]!;
    expect(event).toBeInstanceOf(InboxMessageEvent);
    expect(event.eventType).toBe(InboxEventType.messageActionTaken);
    expect(event.actionName).toBe('messageAction');
    expect(event.actionValue).toBe('https://example.com');
    expect(event.message.queueId).toBe('queue-123');
    expect(event.message.deliveryId).toBe('delivery-456');
    expect(event.message.topics).toEqual(['promo', 'news']);
    expect(event.message.properties).toEqual({ foo: 'bar' });
  });

  it('maps observational callbacks (shown/opened/dismissed) to the listener', () => {
    const inApp = new CustomerIOInAppMessaging();
    const received: InboxEventType[] = [];
    inApp.registerInboxEventListener((event) => received.push(event.eventType));

    native.__emit?.({ eventType: 'messageShown', message: rawMessage });
    native.__emit?.({ eventType: 'messageOpened', message: rawMessage });
    native.__emit?.({ eventType: 'messageDismissed', message: rawMessage });

    expect(received).toEqual([
      InboxEventType.messageShown,
      InboxEventType.messageOpened,
      InboxEventType.messageDismissed,
    ]);
  });

  it('unregisters the native forwarder and stops delivery on remove()', () => {
    const inApp = new CustomerIOInAppMessaging();
    const received: InboxMessageEvent[] = [];
    const subscription = inApp.registerInboxEventListener((event) =>
      received.push(event)
    );

    subscription.remove();

    expect(native.__nativeRemove).toHaveBeenCalledTimes(1);
    expect(native.unregisterInboxEventListener).toHaveBeenCalledTimes(1);
  });
});
