#!/bin/bash

# This script sets up a fresh local dev environment for the example apps.
#
# If invoked while an existing setup exists, it will wipe out all
# installed node modules and pods, and re-install them.

# Use script: ./scripts/sample-apps-init.sh

set -e

# We need to check if the a first argument was passed to the script.
if [ -z "$1" ]; then
  echo "If you want to initialize the ios example app, run the script with the argument \"apn\" or \"fcm\"."
  echo "Since none was passed, the script will initialize Android example app only"
else
  # The argument passed must be either "apn" or "fcm".
  if [ "$1" != "apn" ] && [ "$1" != "fcm" ]; then
    echo "Invalid argument. Please use \"apn\" or \"fcm\"."
    exit 1
  fi
  # Target should be all capitalized.
  TARGET_APP=$(echo "$1" | tr '[:lower:]' '[:upper:]')
  PUSH_PROVIDER="$1"
fi

# Get reference directories
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
EXAMPLES_DIR="$(cd "$SCRIPTS_DIR/.." &>/dev/null && pwd)"
PACKAGE_ROOT_DIR="$(cd "$EXAMPLES_DIR/.." &>/dev/null && pwd)"
# Keep this reference to navigate back to it later.
CURRENT_DIR="$(pwd)"

clean_up() {

  sh "$PACKAGE_ROOT_DIR/scripts/clean_all.sh"

}

set_env_files_if_not_exists() {

  ENV_FILE_NAME="$1"
  ENV_FILE_PATH="$2/$ENV_FILE_NAME"
  ENV_SAMPLE_FILE_PATH="$2/$ENV_FILE_NAME.sample"

  if [ ! -f "$ENV_FILE_PATH" ]; then
    echo "Creating $ENV_FILE_PATH"
    cp "$ENV_SAMPLE_FILE_PATH" "$ENV_FILE_PATH"
  fi
}

install_node_modules() {

  echo "Installing node dependencies"

  cd "$PACKAGE_ROOT_DIR"
  npm install
  echo "✅ Root package node dependencies installed"
  cd "$EXAMPLES_DIR"

  npm run prepare
  set_env_files_if_not_exists "env.ts" "src"

  echo "✅ example apps node dependencies installed"
}

install_cocoapods_gem() {
  cd "$EXAMPLES_DIR"
  bundle install
  echo "✅ cocoapods and its dependencies installed"
}

install_ios_pods() {
  cd "$EXAMPLES_DIR"
  echo "Executing PUSH_PROVIDER=$PUSH_PROVIDER bundle exec pod install"
  PUSH_PROVIDER=$PUSH_PROVIDER bundle exec pod install --project-directory=ios
  echo "✅ Pods installed for iOS with the needed dependencies for the PUSH_PROVIDER push provider"
}

setup_ios_project_if_needed() {

  if [ -n "$PUSH_PROVIDER" ]; then
    echo "Setting up the iOS example app project"
    cd "$EXAMPLES_DIR"
    install_cocoapods_gem
    install_ios_pods
    set_env_files_if_not_exists "Env.swift" "ios/NotificationServiceExtension"
    echo "✅ iOS example app project is ready"
  fi
}

setup_android_project_if_needed() {
  echo "Setting up the Android example app project"
  cd "$EXAMPLES_DIR"
  npm run bundle:android
  echo "✅ Android example app project is ready"
}

clean_up
install_node_modules
setup_ios_project_if_needed
setup_android_project_if_needed

echo "⭐️⭐️⭐️⭐️ The example apps are all set and ready to build and run ⭐️⭐️⭐️⭐️"

if [ -n "$PUSH_PROVIDER" ]; then
  echo "You can now navigate to the example folder and run 'npm run ios' or 'npm run android' to run the example app."
else
  echo "You can now navigate to the example folder and run 'npm run android' to run the android example app."
fi
