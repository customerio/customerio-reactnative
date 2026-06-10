const path = require('path');
const { getDefaultConfig } = require('@react-native/metro-config');

/**
 * Metro configuration
 * https://facebook.github.io/metro/docs/configuration
 *
 * Conditional Customer.io inclusion:
 * `@cio` is the single facade specifier the sample app imports CIO through.
 * The build-time flag CIO_ENABLED decides which file it resolves to:
 *   - CIO_ENABLED=0  -> src/cio/index.noop.ts (inert stub, CIO not bundled)
 *   - otherwise      -> src/cio/index.real.ts (real SDK)
 * This MUST agree with example/react-native.config.js and the iOS Podfile,
 * which gate native linking on the same flag. If they disagree (native off but
 * JS real), the SDK's getEnforcing TurboModules throw at launch.
 *
 * @type {import('metro-config').MetroConfig}
 */
const cioEnabled = process.env.CIO_ENABLED !== '0';
const cioFacade = path.resolve(
  __dirname,
  cioEnabled ? 'src/cio/index.real.ts' : 'src/cio/index.noop.ts'
);

const config = getDefaultConfig(__dirname);

const upstreamResolveRequest = config.resolver.resolveRequest;
config.resolver.resolveRequest = (context, moduleName, platform) => {
  if (moduleName === '@cio') {
    return { type: 'sourceFile', filePath: cioFacade };
  }
  return (upstreamResolveRequest ?? context.resolveRequest)(
    context,
    moduleName,
    platform
  );
};

module.exports = config;
