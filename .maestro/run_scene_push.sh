#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURE_DIR="$REPO_ROOT/.maestro/fixtures/react-native-scene"
APP_NAME="CioRnSceneHost"
APP_ID="org.reactjs.native.example.CioRnSceneHost"
RN_CLI_VERSION="20.2.0"
RN_TEMPLATE_VERSION="0.87.0"
RN_VERSION="0.88.0-nightly-20260823-0c7f63a4e"
DEVELOPER_DIR="${DEVELOPER_DIR:-$(xcode-select -p)}"
if [[ "$DEVELOPER_DIR" == */CommandLineTools && -d /Applications/Xcode.app/Contents/Developer ]]; then
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
export DEVELOPER_DIR

for command in bundle jq maestro node npm npx pod ruby xcodebuild xcrun; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "error: required command '$command' is not installed" >&2
    exit 2
  }
done

device_id="${E2E_DEVICE_ID:-}"
simulator_name="${E2E_SIMULATOR_NAME:-}"
if [[ -z "$device_id" && -n "$simulator_name" ]]; then
  device_id="$(xcrun simctl list devices available -j | jq -r --arg name "$simulator_name" \
    '[.devices[][] | select(.name == $name)][0].udid // empty')"
fi
if [[ -z "$device_id" && -z "$simulator_name" ]]; then
  device_id="$(xcrun simctl list devices booted -j | jq -r \
    '[.devices[][] | select(.state == "Booted") | select(.name | startswith("iPhone"))][0].udid // empty')"
fi
if [[ -z "$device_id" ]]; then
  simulator_name="${simulator_name:-iPhone 17 Pro}"
  device_id="$(xcrun simctl list devices available -j | jq -r --arg name "$simulator_name" \
    '[.devices[][] | select(.name == $name)][0].udid // empty')"
  if [[ -z "$device_id" ]]; then
    echo "error: no available '$simulator_name' simulator; set E2E_DEVICE_ID or E2E_SIMULATOR_NAME" >&2
    exit 2
  fi
  xcrun simctl boot "$device_id" >/dev/null 2>&1 || true
fi
xcrun simctl bootstatus "$device_id" -b

created_host_parent=false
if [[ -n "${CIO_E2E_HOST_PARENT:-}" ]]; then
  host_parent="$CIO_E2E_HOST_PARENT"
else
  host_parent="$(mktemp -d "${TMPDIR:-/tmp}/cio-rn-scene-e2e.XXXXXX")"
  created_host_parent=true
fi
host="$host_parent/$APP_NAME"
package_dir="$host_parent/package"
derived_data="$host_parent/derived-data"
flow_log=""
flow_pid=""
installed_app=false
cleanup() {
  if [[ -n "$flow_pid" ]]; then
    kill "$flow_pid" >/dev/null 2>&1 || true
    wait "$flow_pid" 2>/dev/null || true
  fi
  if [[ -n "$flow_log" ]]; then
    rm -f "$flow_log"
  fi
  if [[ "$installed_app" == true ]]; then
    xcrun simctl terminate "$device_id" "$APP_ID" >/dev/null 2>&1 || true
    xcrun simctl uninstall "$device_id" "$APP_ID" >/dev/null 2>&1 || true
  fi
  if [[ "$created_host_parent" == true && -d "$host_parent" ]]; then
    find "$host_parent" -depth -delete
  fi
}
trap cleanup EXIT
mkdir -p "$package_dir"

run_notification_flow() {
  local flow="$1"
  local payload="$2"
  local ready=false
  local status=0
  local flow_name="${flow##*/}"
  local maestro_args=(--device "$device_id" test "$flow")

  flow_name="${flow_name%.yaml}"
  if [[ -n "${RUNNER_TEMP:-}" ]]; then
    maestro_args=(
      --device "$device_id"
      test
      --debug-output "$RUNNER_TEMP/react-native-scene-maestro-$flow_name"
      --flatten-debug-output
      "$flow"
    )
  fi

  flow_log="$(mktemp "${TMPDIR:-/tmp}/cio-rn-maestro-flow.XXXXXX")"
  maestro "${maestro_args[@]}" > >(tee "$flow_log") 2>&1 &
  flow_pid=$!

  for _ in {1..240}; do
    if grep -q 'Press Home key.*COMPLETED' "$flow_log"; then
      ready=true
      break
    fi
    if ! kill -0 "$flow_pid" >/dev/null 2>&1; then
      if wait "$flow_pid"; then
        echo "error: Maestro completed before reaching the Home screen" >&2
      else
        status=$?
        echo "error: Maestro exited before reaching the Home screen (status $status)" >&2
      fi
      flow_pid=""
      return 1
    fi
    sleep 0.5
  done

  if [[ "$ready" != true ]]; then
    echo "error: Maestro did not reach the Home screen before notification injection" >&2
    return 1
  fi

  xcrun simctl push "$device_id" "$APP_ID" "$payload"
  if ! wait "$flow_pid"; then
    flow_pid=""
    return 1
  fi
  flow_pid=""
  rm -f "$flow_log"
  flow_log=""
}

cd "$REPO_ROOT"
npm ci
package_name="$(npm pack --silent --pack-destination "$package_dir" | tail -n 1)"

cd "$host_parent"
npx "@react-native-community/cli@$RN_CLI_VERSION" init "$APP_NAME" \
  --version "$RN_VERSION" \
  --template "@react-native-community/template@$RN_TEMPLATE_VERSION" \
  --skip-install
cd "$host"
npm pkg set \
  "dependencies.react-native=$RN_VERSION" \
  "dependencies.@react-native/new-app-screen=$RN_VERSION"
npm pkg set \
  "devDependencies.@react-native/babel-preset=$RN_VERSION" \
  "devDependencies.@react-native/eslint-config=$RN_VERSION" \
  "devDependencies.@react-native/jest-preset=$RN_VERSION" \
  "devDependencies.@react-native/metro-config=$RN_VERSION" \
  "devDependencies.@react-native/typescript-config=$RN_VERSION"
npm install
npm install "$package_dir/$package_name"

cp "$FIXTURE_DIR/App.tsx" App.tsx
cp "$FIXTURE_DIR/AppDelegate.swift" "ios/$APP_NAME/AppDelegate.swift"
cp "$FIXTURE_DIR/SceneDelegate.swift" "ios/$APP_NAME/SceneDelegate.swift"

plist="ios/$APP_NAME/Info.plist"
/usr/libexec/PlistBuddy -c 'Delete :UIApplicationSceneManifest' "$plist" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c 'Add :UIApplicationSceneManifest dict' "$plist"
/usr/libexec/PlistBuddy -c 'Add :UIApplicationSceneManifest:UISceneConfigurations dict' "$plist"
/usr/libexec/PlistBuddy -c 'Add :UIApplicationSceneManifest:UISceneConfigurations:UIWindowSceneSessionRoleApplication array' "$plist"
/usr/libexec/PlistBuddy -c 'Add :UIApplicationSceneManifest:UISceneConfigurations:UIWindowSceneSessionRoleApplication:0 dict' "$plist"
/usr/libexec/PlistBuddy -c 'Add :UIApplicationSceneManifest:UISceneConfigurations:UIWindowSceneSessionRoleApplication:0:UISceneConfigurationName string Default Configuration' "$plist"
# shellcheck disable=SC2016
/usr/libexec/PlistBuddy -c 'Add :UIApplicationSceneManifest:UISceneConfigurations:UIWindowSceneSessionRoleApplication:0:UISceneDelegateClassName string $(PRODUCT_MODULE_NAME).SceneDelegate' "$plist"

bundle install
bundle exec ruby "$FIXTURE_DIR/configure_podfile.rb" ios/Podfile
bundle exec ruby "$FIXTURE_DIR/configure.rb" "ios/$APP_NAME.xcodeproj" "$APP_NAME"
bundle exec pod install --project-directory=ios

node node_modules/react-native/scripts/bundle.js \
  --platform ios \
  --dev false \
  --entry-file index.js \
  --bundle-output "ios/main.jsbundle" \
  --assets-dest ios

xcodebuild -quiet \
  -workspace "ios/$APP_NAME.xcworkspace" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -destination "platform=iOS Simulator,id=$device_id" \
  -derivedDataPath "$derived_data" \
  CODE_SIGNING_ALLOWED=NO \
  build

app_path="$derived_data/Build/Products/Release-iphonesimulator/$APP_NAME.app"
test -d "$app_path"
xcrun simctl uninstall "$device_id" "$APP_ID" >/dev/null 2>&1 || true
xcrun simctl install "$device_id" "$app_path"
installed_app=true

cd "$REPO_ROOT"
maestro --device "$device_id" test .maestro/scene_push_prepare.yaml
xcrun simctl terminate "$device_id" "$APP_ID"
run_notification_flow .maestro/scene_push_open.yaml .maestro/fixtures/customerio_scene_cold.apns
run_notification_flow .maestro/scene_push_warm.yaml .maestro/fixtures/customerio_scene_warm.apns
