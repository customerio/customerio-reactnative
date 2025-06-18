#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

/**
 * Sync codegen files from build directory to platform generated directories
 * This script runs after codegen generates files and syncs platform-specific files
 * so React Native autolinking works and finds the classes where it expects them.
 *
 * Usage:
 *   node scripts/codegen-sync.js                    # runs for all platforms
 *   node scripts/codegen-sync.js --platform=android # explicit android only
 *   node scripts/codegen-sync.js --platform=ios     # ios only (currently unsupported)
 */

// Read package name from package.json
const rootDir = path.resolve(__dirname, '..');
const packageJson = JSON.parse(
  fs.readFileSync(path.join(rootDir, 'package.json'), 'utf8')
);
const PACKAGE_NAME = packageJson.name;

function log(message, ...args) {
  console.log(`[${PACKAGE_NAME}]`, message, ...args);
}

function logError(message, ...args) {
  console.error(`[${PACKAGE_NAME}]`, message, ...args);
}

function copyDir(src, dest) {
  // Create destination directory if it doesn't exist
  if (!fs.existsSync(dest)) {
    fs.mkdirSync(dest, { recursive: true });
  }

  const items = fs.readdirSync(src);

  for (const item of items) {
    const srcPath = path.join(src, item);
    const destPath = path.join(dest, item);
    const stat = fs.statSync(srcPath);

    if (stat.isDirectory()) {
      copyDir(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}

function getPlatformPaths(platform) {
  const platforms = {
    android: {
      sourceDir: path.join(
        rootDir,
        'android',
        'generated',
        'android',
        'app',
        'build',
        'generated',
        'source',
        'codegen'
      ),
      targetDir: path.join(rootDir, 'android', 'generated'),
    },
  };

  return platforms[platform];
}

function copyCodegenForPlatform(platform) {
  const paths = getPlatformPaths(platform);

  if (!paths) {
    logError(`❌ Unsupported platform: ${platform}`);
    return false;
  }

  const { sourceDir, targetDir } = paths;

  if (!fs.existsSync(sourceDir)) {
    log(`Codegen source directory not found for ${platform}:`, sourceDir);
    log(`Skipping ${platform} copy operation.`);
    return true; // Not an error, just skip
  }

  try {
    log(`Copying codegen files for ${platform}...`);
    log('From:', sourceDir);
    log('To:', targetDir);

    // Copy all files and directories from source to target
    const items = fs.readdirSync(sourceDir);
    for (const item of items) {
      const srcPath = path.join(sourceDir, item);
      const destPath = path.join(targetDir, item);

      if (fs.statSync(srcPath).isDirectory()) {
        copyDir(srcPath, destPath);
      } else {
        if (!fs.existsSync(targetDir)) {
          fs.mkdirSync(targetDir, { recursive: true });
        }
        fs.copyFileSync(srcPath, destPath);
      }
    }

    log(`✅ ${platform} codegen files copied successfully`);
    return true;
  } catch (error) {
    logError(`❌ Error copying ${platform} codegen files:`, error.message);
    return false;
  }
}

function main() {
  // rootDir is already defined at the top of the file

  // Get platform from command line args
  const args = process.argv.slice(2);
  const platformArg = args.find((arg) => arg.startsWith('--platform='));

  if (platformArg) {
    // Run for specific platform
    const platform = platformArg.split('=')[1];
    const success = copyCodegenForPlatform(platform);

    if (!success) {
      process.exit(1);
    }
  } else {
    // Run for both platforms when no platform specified
    log('No platform specified, running sync for all platforms...');

    let allSuccessful = true;
    const platforms = ['android', 'ios'];

    for (const platform of platforms) {
      const success = copyCodegenForPlatform(platform, rootDir);
      if (!success) {
        allSuccessful = false;
      }
    }

    if (!allSuccessful) {
      process.exit(1);
    }
  }
}

if (require.main === module) {
  main();
}

module.exports = { main, copyCodegenForPlatform, getPlatformPaths };
