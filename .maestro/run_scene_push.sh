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
export MAESTRO_CLI_NO_ANALYTICS=1

for command in bundle jq maestro node npm npx ruby xcodebuild xcrun; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "error: required command '$command' is not installed" >&2
    exit 2
  }
done

maestro_version="$(maestro --version | tr -d '\r')"
if [[ "$maestro_version" != '2.8.0' ]]; then
  echo "error: Maestro 2.8.0 is required; found '$maestro_version'" >&2
  exit 2
fi

runtime_major="${E2E_IOS_RUNTIME_MAJOR:-27}"
runtime_fragment=".iOS-${runtime_major}-"
simulator_devices="$(xcrun simctl list devices available -j)"
device_id="${E2E_DEVICE_ID:-}"
simulator_name="${E2E_SIMULATOR_NAME:-}"
if [[ -z "$device_id" && -n "$simulator_name" ]]; then
  device_id="$(jq -r --arg name "$simulator_name" --arg runtime "$runtime_fragment" \
    '[.devices | to_entries[] | select(.key | contains($runtime)) | .value[] | select(.name == $name)][0].udid // empty' \
    <<< "$simulator_devices")"
fi
if [[ -z "$device_id" && -z "$simulator_name" ]]; then
  device_id="$(jq -r --arg runtime "$runtime_fragment" \
    '[.devices | to_entries[] | select(.key | contains($runtime)) | .value[] | select(.state == "Booted") | select(.name | startswith("iPhone"))][0].udid // empty' \
    <<< "$simulator_devices")"
fi
if [[ -z "$device_id" ]]; then
  simulator_name="${simulator_name:-iPhone 17 Pro}"
  device_id="$(jq -r --arg name "$simulator_name" --arg runtime "$runtime_fragment" \
    '[.devices | to_entries[] | select(.key | contains($runtime)) | .value[] | select(.name == $name)][0].udid // empty' \
    <<< "$simulator_devices")"
  if [[ -z "$device_id" ]]; then
    echo "error: no available '$simulator_name' simulator on iOS $runtime_major; set E2E_DEVICE_ID, E2E_SIMULATOR_NAME, or E2E_IOS_RUNTIME_MAJOR" >&2
    exit 2
  fi
fi
runtime_id="$(jq -r --arg id "$device_id" \
  '[.devices | to_entries[] | select(any(.value[]; .udid == $id))][0].key // empty' \
  <<< "$simulator_devices")"
if [[ "$runtime_id" != *"$runtime_fragment"* ]]; then
  echo "error: selected simulator runtime '$runtime_id' is not iOS $runtime_major" >&2
  exit 2
fi
simulator_started_by_runner=false
created_host_parent=false
host_parent=""
package_dir=""
derived_data=""
flow_log=""
flow_pid=""
installed_app=false
current_phase="setup"
cleanup() {
  local exit_code=$?
  set +e
  if [[ "$exit_code" -ne 0 && -n "${RUNNER_TEMP:-}" ]] && \
    xcrun simctl list devices booted -j | jq -e --arg id "$device_id" \
      'any(.devices[][]; .udid == $id and .state == "Booted")' >/dev/null; then
    xcrun simctl spawn "$device_id" log show \
      --last 15m \
      --style compact \
      --predicate "process == '$APP_NAME'" \
      > "$RUNNER_TEMP/react-native-scene-maestro-device.log" 2>&1 || true
  fi
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
  if [[ "$simulator_started_by_runner" == true ]]; then
    xcrun simctl shutdown "$device_id" >/dev/null 2>&1 || true
  fi
  if [[ "$created_host_parent" == true && -n "$host_parent" && -d "$host_parent" ]]; then
    if ! find "$host_parent" -depth -delete; then
      echo "warning: could not completely remove temporary host $host_parent" >&2
    fi
  fi
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    {
      echo '## React Native scene notification routing'
      echo
      if [[ "$exit_code" -eq 0 ]]; then
        echo '**Classification:** scene-routing-passed'
      else
        echo "**Classification:** ${current_phase}-failed"
      fi
      echo '**Scope:** simulator notification presentation, tap, ordinary warm and cold URLs, and exact acknowledged-handler and legacy-Linking destinations; no backend delivery or attribution claim'
    } >> "$GITHUB_STEP_SUMMARY"
  fi
  return "$exit_code"
}
trap cleanup EXIT

if ! jq -e --arg id "$device_id" \
  'any(.devices[][]; .udid == $id and .state == "Booted")' <<< "$simulator_devices" >/dev/null; then
  xcrun simctl boot "$device_id"
  simulator_started_by_runner=true
fi
xcrun simctl bootstatus "$device_id" -b

if [[ -n "${CIO_E2E_HOST_PARENT:-}" ]]; then
  host_parent="$CIO_E2E_HOST_PARENT"
else
  host_parent="$(mktemp -d "${TMPDIR:-/tmp}/cio-rn-scene-e2e.XXXXXX")"
  created_host_parent=true
fi
host="$host_parent/$APP_NAME"
package_dir="$host_parent/package"
derived_data="$host_parent/derived-data"
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

  local push_output
  if ! push_output="$(xcrun simctl push "$device_id" "$APP_ID" "$payload" 2>&1)"; then
    printf '%s\n' "$push_output" >&2
    if grep -q 'UNErrorDomain.*2003\|Source is not authorized' <<< "$push_output"; then
      echo "error: simulator notification authorization was not granted; notification routing was not exercised" >&2
    else
      echo "error: simctl could not inject the notification fixture" >&2
    fi
    return 1
  fi
  printf '%s\n' "$push_output"
  if ! wait "$flow_pid"; then
    flow_pid=""
    return 1
  fi
  flow_pid=""
  rm -f "$flow_log"
  flow_log=""
}

run_ordinary_url_flow() {
  local url="$1"
  local state="$2"
  local ordinary_args=(
    --device "$device_id"
    test
    -e "EXPECTED_URL=$url"
    .maestro/scene_url_open.yaml
  )

  xcrun simctl openurl "$device_id" "$url"
  if [[ -n "${RUNNER_TEMP:-}" ]]; then
    ordinary_args=(
      --device "$device_id"
      test
      --debug-output "$RUNNER_TEMP/react-native-scene-maestro-scene_url_open-$state"
      --flatten-debug-output
      -e "EXPECTED_URL=$url"
      .maestro/scene_url_open.yaml
    )
  fi
  maestro "${ordinary_args[@]}"
}

cd "$REPO_ROOT"
current_phase="package"
npm ci
package_name="$(npm pack --silent --pack-destination "$package_dir" | tail -n 1)"

cd "$host_parent"
current_phase="generate"
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
current_phase="install"
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
/usr/libexec/PlistBuddy -c 'Add :CFBundleURLTypes array' "$plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleURLTypes:0 dict' "$plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleURLTypes:0:CFBundleURLSchemes array' "$plist"
/usr/libexec/PlistBuddy -c 'Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string cio-rn-scene-e2e' "$plist"

current_phase="pods"
bundle install
bundle exec ruby "$FIXTURE_DIR/configure_podfile.rb" ios/Podfile
bundle exec ruby "$FIXTURE_DIR/configure.rb" "ios/$APP_NAME.xcodeproj" "$APP_NAME"
bundle exec pod install --project-directory=ios

current_phase="compile"
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
for routing_mode in acknowledged linking; do
  current_phase="prepare-$routing_mode"
  prepare_args=(--device "$device_id" test -e "ROUTING_MODE=$routing_mode" .maestro/scene_push_prepare.yaml)
  if [[ -n "${RUNNER_TEMP:-}" ]]; then
    prepare_args=(
      --device "$device_id"
      test
      --debug-output "$RUNNER_TEMP/react-native-scene-maestro-scene_push_prepare-$routing_mode"
      --flatten-debug-output
      -e "ROUTING_MODE=$routing_mode"
      .maestro/scene_push_prepare.yaml
    )
  fi
  maestro "${prepare_args[@]}"

  if [[ "$routing_mode" == acknowledged ]]; then
    current_phase="ordinary-link-warm-$routing_mode"
    run_ordinary_url_flow 'cio-rn-scene-e2e://ordinary-warm' warm
    xcrun simctl terminate "$device_id" "$APP_ID"

    current_phase="ordinary-link-cold-$routing_mode"
    run_ordinary_url_flow 'cio-rn-scene-e2e://ordinary-cold' cold
  fi
  xcrun simctl terminate "$device_id" "$APP_ID"

  current_phase="routing-$routing_mode"
  run_notification_flow .maestro/scene_push_open.yaml .maestro/fixtures/customerio_scene_cold.apns
  run_notification_flow .maestro/scene_push_warm.yaml .maestro/fixtures/customerio_scene_warm.apns
  if [[ "$routing_mode" == acknowledged ]]; then
    run_notification_flow .maestro/scene_push_declined.yaml .maestro/fixtures/customerio_scene_declined.apns
  fi
done
