#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

/**
 * Sync codegen files from build directory to platform generated directories
 * This script runs after codegen generates files and syncs platform-specific files
 * so React Native autolinking works and finds the classes where it expects them.
 *
 * The script automatically reads output directories from package.json codegenConfig.outputDir
 * and falls back to default paths if the configuration is not found.
 *
 * Usage:
 *   node scripts/codegen-sync.js                    # runs for all platforms
 *   node scripts/codegen-sync.js --platform=android # explicit android only
 *   node scripts/codegen-sync.js --platform=ios     # ios only
 */

// Read package.json for configuration
const rootDir = path.resolve(__dirname, '..');
const packageJson = JSON.parse(
  fs.readFileSync(path.join(rootDir, 'package.json'), 'utf8')
);
const PACKAGE_NAME = packageJson.name;
const codegenConfig = packageJson.codegenConfig;

// Validate codegenConfig
if (!codegenConfig) {
  console.warn(
    `[${PACKAGE_NAME}] Warning: No codegenConfig found in package.json. Using default paths.`
  );
} else if (!codegenConfig.outputDir) {
  console.warn(
    `[${PACKAGE_NAME}] Warning: No outputDir found in codegenConfig. Using default paths.`
  );
}

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

function removeDir(dir) {
  try {
    if (fs.existsSync(dir)) {
      fs.rmSync(dir, { recursive: true, force: true });
      return true;
    }
    return true; // Directory doesn't exist, consider it success
  } catch (error) {
    logError(`❌ Error removing directory ${dir}:`, error.message);
    return false;
  }
}

function removeEmptyDirsUpwards(startDir, stopDir) {
  try {
    let currentDir = startDir;

    while (currentDir !== stopDir && currentDir !== path.dirname(currentDir)) {
      // Check if directory exists and is empty
      if (fs.existsSync(currentDir)) {
        const items = fs.readdirSync(currentDir);
        if (items.length === 0) {
          fs.rmdirSync(currentDir);
          log(`Removed empty directory: ${currentDir}`);
          currentDir = path.dirname(currentDir);
        } else {
          // Directory is not empty, stop cleanup
          break;
        }
      } else {
        // Directory doesn't exist, move up
        currentDir = path.dirname(currentDir);
      }
    }
  } catch (error) {
    // Silently fail - this is cleanup, not critical
    log(
      `⚠️  Warning: Could not remove some empty directories: ${error.message}`
    );
  }
}

function getPlatformPaths(platform) {
  // Get target directory from codegenConfig if available, otherwise use defaults
  const getTargetDir = () => {
    if (codegenConfig?.outputDir?.[platform]) {
      const configPath = codegenConfig.outputDir[platform];
      return path.join(rootDir, configPath);
    }
    // Fallback to hardcoded values if config is missing
    const defaultPath = path.join(platform, 'generated');
    return path.join(rootDir, defaultPath);
  };

  const targetDir = getTargetDir();

  const platforms = {
    android: {
      sourceDir: path.join(
        targetDir,
        'android',
        'app',
        'build',
        'generated',
        'source',
        'codegen'
      ),
      targetDir,
      cleanupStopDir: targetDir,
    },
    ios: {
      sourceDir: path.join(targetDir, 'build', 'generated', 'ios'),
      targetDir,
      cleanupStopDir: targetDir,
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

  const { sourceDir, targetDir, cleanupStopDir } = paths;

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

    // Clean up original generated files to avoid duplication
    log(`Cleaning up original generated files from: ${sourceDir}`);
    const cleanupSuccess = removeDir(sourceDir);
    if (!cleanupSuccess) {
      log(
        `⚠️  Warning: Failed to remove original generated files at ${sourceDir}. This may cause duplication but won't affect functionality.`
      );
    } else {
      log(`✅ Original generated files cleaned up successfully`);
      // Clean up empty directories upwards from the source dir to the platform stop dir
      removeEmptyDirsUpwards(path.dirname(sourceDir), cleanupStopDir);
    }

    return true;
  } catch (error) {
    logError(`❌ Error copying ${platform} codegen files:`, error.message);
    return false;
  }
}

function logConfiguration() {
  log('Codegen sync configuration:');
  if (codegenConfig?.outputDir) {
    log('  From codegenConfig.outputDir:');
    Object.entries(codegenConfig.outputDir).forEach(([platform, dir]) => {
      log(`    ${platform}: ${dir}`);
    });
  } else {
    log('  Using default paths (no codegenConfig.outputDir found)');
  }
}

function main() {
  logConfiguration();

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
