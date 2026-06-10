/**
 * Real Customer.io integration.
 *
 * Metro resolves `@cio` to this file when the build flag CIO_ENABLED !== '0'
 * (the default), and TypeScript always resolves `@cio` here for types (see the
 * `paths` entry in example/tsconfig.json). App code imports CIO only through
 * `@cio`, never from 'customerio-reactnative' directly, so a single Metro
 * resolver decision swaps the entire SDK for a no-op stand-in.
 */
export * from 'customerio-reactnative';

