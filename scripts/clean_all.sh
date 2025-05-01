#!/bin/bash

# This script sets up a fresh local dev environment for the example apps.
#
# If invoked while an existing setup exists, it will wipe out all
# installed node modules and pods, and re-install them.

# Use script: ./scripts/clean_all.sh

set -e

# Get reference directories
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PACKAGE_ROOT_DIR="$(cd "$SCRIPTS_DIR/.." &>/dev/null && pwd)"
EXAMPLES_DIR="$(cd "$PACKAGE_ROOT_DIR/example" &>/dev/null && pwd)"
# Keep this reference to navigate back to it later.
CURRENT_DIR="$(pwd)"

clean_up() {
  echo "Wiping all node_modules, all ios and android generated files"

  cd "$PACKAGE_ROOT_DIR"
  # Clean node cache
  npm cache clean --force

  # Clean up the root
  rm -rf node_modules
  rm -rf vendor
  rm -rf lib
  rm -f package-lock.json
  rm -f yarn.lock

  # Clean up the tarball file
  rm -f customerio-reactnative.tgz

  cd "$EXAMPLES_DIR"
  # Clean up the example ios app
  rm -rf ios/Pods
  rm -rf ios/build
  rm -f ios/Podfile.lock
  rm -rf ios/SampleApp.xcworkspace
  rm -rf ios/.xcode.env.local

  # Clean up gem files
  rm -rf vendor
  rm -f Gemfile.lock

  # Clean up the example android app
  rm -rf android/.gradle
  rm -rf android/.idea
  rm -rf android/.kotlin
  rm -rf android/build
  rm -rf android/app/build
  rm -rf android/app/.cxx
  rm -rf android/app/src/main/assets/index.android.bundle

  # Clean node cache
  npm cache clean --force
  # Clean up the example app node_modules
  rm -rf node_modules
  rm -f package-lock.json

  echo "✅ Clean up completed"
}

clean_up
