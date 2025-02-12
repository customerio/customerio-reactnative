import { getVersion } from 'react-native-device-info';
import Env from '../../env';

const BuildMetadata = {
  sdkVersion: getSdkVersion(),
  appVersion: resolveValidOrElse(getVersion()),
  buildDate: formatBuildDateWithRelativeTime(Env.buildTimestamp),
  gitMetadata: `${resolveValidOrElse(
    Env.branchName,
    () => 'development build'
  )}-${resolveValidOrElse(Env.commitHash, () => 'untracked')}`,
  defaultWorkspace: resolveValidOrElse(Env.workspaceName),
  language: 'JavaScript',
  uiFramework: 'React Native',
  sdkIntegration: 'npm',

  toString() {
    return `
      SDK Version: ${this.sdkVersion} \tApp Version: ${this.appVersion}
      Build Date: ${this.buildDate}
      Branch: ${this.gitMetadata}
      Default Workspace: ${this.defaultWorkspace}
      Language: ${this.language} \tUI Framework: ${this.uiFramework}
      SDK Integration: ${this.sdkIntegration}
    `;
  },
};

function resolveValidOrElse(value, fallback = () => 'unknown') {
  return value && value.trim() ? value : fallback();
}

function formatBuildDateWithRelativeTime(timestamp) {
  if (!timestamp) return 'unavailable';
  const parsedTimestamp = parseInt(timestamp, 10);
  if (isNaN(parsedTimestamp)) return 'invalid timestamp';

  const buildDate = new Date(parsedTimestamp * 1000);
  const now = new Date();
  const daysAgo = Math.floor((now - buildDate) / (1000 * 60 * 60 * 24));

  return `${buildDate.toLocaleString()} ${
    daysAgo === 0 ? '(Today)' : `(${daysAgo} days ago)`
  }`;
}

function getSdkVersion() {
  try {
    const sdkPackageName = 'customerio-reactnative';
    const sdkPackage = getSdkMetadataFromPackageLock(sdkPackageName);

    if (!sdkPackage) {
      console.warn(`${sdkPackageName} not found in package-lock.json`);

      const sdkPackageJson = require('customerio-reactnative/package.json');
      return sdkPackageJson.version;
    }

    const version = resolveValidOrElse(sdkPackage.version);
    const isPathDependency =
      sdkPackage.resolved && sdkPackage.resolved.startsWith('file:');
    if (isPathDependency) {
      const commitsAheadCount = Env.commitsAheadCount;
      return `${version}-${resolveValidOrElse(
        commitsAheadCount,
        () => 'as-source'
      )}`;
    }

    return version;
  } catch (error) {
    console.warn(
      `Failed to read customerio-reactnative sdk version: ${error.message}`
    );
    return undefined;
  }
}

function getSdkMetadataFromPackageLock(packageName) {
  const packageLockPath = '../../package-lock.json';
  try {
    const packageLock = require(packageLockPath);
    const packages = packageLock.packages || {};
    const resolvedPackageName = `node_modules/${packageName}`;
    const sdkPackage = packages[resolvedPackageName];
    if (sdkPackage) {
      return sdkPackage;
    }
  } catch (error) {
    console.warn(`Failed to read ${packageLockPath}: ${error.message}`);
  }
  return undefined;
}

export { BuildMetadata };
