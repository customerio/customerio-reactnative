/**
 * No-op stand-in for `customerio-reactnative`.
 *
 * Metro resolves `@cio` to this file when the build flag CIO_ENABLED === '0'
 * (see example/metro.config.js). It lets the sample app build, bundle, and run
 * with Customer.io completely excluded — no native module linked, none of the
 * SDK's JS bundled, and zero runtime footprint.
 *
 * Why a hand-written stub instead of a lazy/conditional `import()` of the real
 * package: every native bridge in customerio-reactnative is registered with
 * `TurboModuleRegistry.getEnforcing(...)`, which THROWS at module-evaluation
 * time when the native module isn't linked. With CIO_ENABLED=0 the native
 * module is intentionally not linked (see example/react-native.config.js), so
 * the real JS must never be imported. Hence this file imports no runtime value
 * from 'customerio-reactnative'. Type-only re-exports below are erased by the
 * compiler, so they cost nothing at runtime yet keep every call site fully
 * typed against the genuine SDK surface.
 */

// --- Types: erased at build time, safe to re-export from the real package. ---
export type {
  CioConfig,
  InAppMessage,
  InAppMessageEvent,
  InboxMessage,
} from 'customerio-reactnative';

// --- Enums: redefined verbatim. They cannot be imported from the package ---
// --- root, because evaluating that module triggers the getEnforcing specs. ---
export enum CioPushPermissionStatus {
  Granted = 'GRANTED',
  Denied = 'DENIED',
  NotDetermined = 'NOTDETERMINED',
}
export enum CioLogLevel {
  None = 'none',
  Error = 'error',
  Info = 'info',
  Debug = 'debug',
}
export enum CioRegion {
  US = 'US',
  EU = 'EU',
}
export enum CioLocationTrackingMode {
  Off = 'OFF',
  Manual = 'MANUAL',
  OnAppStart = 'ON_APP_START',
}
export enum InAppMessageEventType {
  errorWithMessage = 'errorWithMessage',
  messageActionTaken = 'messageActionTaken',
  messageDismissed = 'messageDismissed',
  messageShown = 'messageShown',
}

// --- Inert runtime stubs. Never throw, never touch NativeModules. ---
const noop = () => {};
const asyncNoop = async () => {};
const subscription = { remove: () => {} };

const inbox = {
  subscribeToMessages: (_opts?: unknown) => subscription,
  getMessages: async () => [],
  markMessageOpened: noop,
  markMessageUnopened: noop,
  markMessageDeleted: noop,
  trackMessageClicked: noop,
};

const inAppMessaging = {
  registerEventsListener: (_listener: unknown) => subscription,
  dismissMessage: noop,
  inbox: () => inbox,
};

const location = {
  setLastKnownLocation: noop,
  requestLocationUpdate: noop,
};

const pushMessaging = {
  showPromptForPushNotifications: async () =>
    CioPushPermissionStatus.NotDetermined,
};

const CustomerIONoop = {
  initialize: noop,
  identify: noop,
  clearIdentify: asyncNoop,
  track: noop,
  screen: noop,
  setProfileAttributes: noop,
  setDeviceAttributes: noop,
  inAppMessaging,
  location,
  pushMessaging,
};

// Cast the inert objects to the real SDK types so call sites are still checked
// against the genuine interface (TypeScript resolves @cio -> index.real).
export const CustomerIO =
  CustomerIONoop as unknown as typeof import('customerio-reactnative').CustomerIO;

export const InlineInAppMessageView = ((_props: unknown) =>
  null) as unknown as typeof import('customerio-reactnative').InlineInAppMessageView;

