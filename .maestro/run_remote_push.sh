#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAESTRO_DIR="$REPO_ROOT/.maestro"
SAMPLE_ROOT="$REPO_ROOT/example"
APP_ID="io.customer.ami"
MOBILE_E2E_REF="7c7912eedc96fdd623dcb8a7c0d9111feae56d39"
DEVELOPER_DIR="${DEVELOPER_DIR:-$(xcode-select -p)}"
if [[ "$DEVELOPER_DIR" == */CommandLineTools && -d /Applications/Xcode.app/Contents/Developer ]]; then
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
export DEVELOPER_DIR
export PUSH_PROVIDER=apn

if ! bundle _2.6.9_ --version >/dev/null 2>&1; then
  if [[ "${CIO_E2E_RUBY_READY:-false}" != "true" ]] && command -v mise >/dev/null 2>&1; then
    exec env CIO_E2E_RUBY_READY=true mise x ruby@3.4 -- "$0" "$@"
  fi
  echo "error: Ruby 3.4 with Bundler 2.6.9 is required" >&2
  exit 2
fi

if [[ -f "$MAESTRO_DIR/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$MAESTRO_DIR/.env"
  set +a
fi
: "${MAESTRO_APP_API_KEY:=${MAESTRO_EXT_API_KEY:-}}"
: "${MAESTRO_EXT_API_BASE_URL:=https://api.customer.io/v1}"
export MAESTRO_APP_API_KEY MAESTRO_EXT_API_BASE_URL

die() {
  echo "error: $*" >&2
  exit 2
}

for required_command in bundle curl git jq maestro node npm plutil python3 ruby xcodebuild xcrun; do
  command -v "$required_command" >/dev/null 2>&1 || die "required command '$required_command' is not installed"
done

[[ -n "${MAESTRO_APP_API_KEY:-}" ]] || die "MAESTRO_APP_API_KEY is missing; set it or create .maestro/.env"
[[ "$MAESTRO_APP_API_KEY" != *paste-* ]] || die "MAESTRO_APP_API_KEY still contains a placeholder"

app_env="$SAMPLE_ROOT/src/env.ts"
nse_env="$SAMPLE_ROOT/ios/NotificationServiceExtension/Env.swift"
[[ -f "$app_env" ]] || die "APN sample config is missing: $app_env"

backend_status="$(curl -sS --retry 3 --retry-all-errors --retry-delay 2 --connect-timeout 10 \
  -o /dev/null -w '%{http_code}' \
  -H "Authorization: Bearer $MAESTRO_APP_API_KEY" \
  "$MAESTRO_EXT_API_BASE_URL/customers?email=maestro-doctor-no-match%40cio.test" || true)"
[[ "$backend_status" == "200" ]] || die "Customer.io App API preflight returned HTTP ${backend_status:-unreachable}"

campaign_response="$(curl -sS --retry 3 --retry-all-errors --retry-delay 2 --connect-timeout 10 \
  -w $'\n%{http_code}' \
  -H "Authorization: Bearer $MAESTRO_APP_API_KEY" \
  "$MAESTRO_EXT_API_BASE_URL/campaigns/68" || true)"
campaign_status="${campaign_response##*$'\n'}"
campaign_body="${campaign_response%$'\n'*}"
[[ "$campaign_status" == "200" ]] || \
  die "App API key cannot access campaign 68 in the Mobile: React Native workspace (HTTP ${campaign_status:-unreachable})"
campaign_name="$(printf '%s' "$campaign_body" | jq -r '.campaign.name // .name // empty' 2>/dev/null || true)"
[[ "$campaign_name" == "Maestro React Native APNs E2E" ]] || \
  die "campaign 68 is not the expected Mobile: React Native Maestro APNs automation"

device_id="${E2E_DEVICE_ID:-}"
simulator_name="${E2E_SIMULATOR_NAME:-}"
if [[ -z "$device_id" && -n "$simulator_name" ]]; then
  device_id="$(xcrun simctl list devices available -j | jq -r --arg name "$simulator_name" \
    '[.devices[][] | select(.name == $name)][0].udid // empty')"
fi
if [[ -z "$device_id" ]]; then
  device_id="$(xcrun simctl list devices booted -j | jq -r \
    '[.devices[][] | select(.state == "Booted") | select(.name | startswith("iPhone"))][0].udid // empty')"
fi
if [[ -z "$device_id" ]]; then
  simulator_name="${simulator_name:-iPhone 17 Pro}"
  device_id="$(xcrun simctl list devices available -j | jq -r --arg name "$simulator_name" \
    '[.devices[][] | select(.name == $name)][0].udid // empty')"
fi
[[ -n "$device_id" ]] || die "no available iPhone simulator; set E2E_DEVICE_ID or E2E_SIMULATOR_NAME"
simulator_started_by_runner=false
if ! xcrun simctl list devices booted -j | jq -e --arg id "$device_id" \
  'any(.devices[][]; .udid == $id and .state == "Booted")' >/dev/null; then
  xcrun simctl boot "$device_id"
  simulator_started_by_runner=true
fi
xcrun simctl bootstatus "$device_id" -b

temp_base="${TMPDIR:-/tmp}"
temp_base="${temp_base%/}"
run_root="$(mktemp -d "$temp_base/cio-rn-remote-push.XXXXXX")"
harness="$run_root/mobile-e2e"
derived_data="$run_root/derived-data"
artifacts="$run_root/maestro-artifacts"
artifact_export_dir="${CIO_E2E_ARTIFACT_DIR:-}"
installed_app=false
nse_env_generated=false
nse_env_backup="$run_root/Env.swift.original"
package_lock="$SAMPLE_ROOT/package-lock.json"
package_lock_backup="$run_root/example-package-lock.json"
gemfile_lock="$SAMPLE_ROOT/Gemfile.lock"
gemfile_lock_backup="$run_root/example-Gemfile.lock"
cp "$package_lock" "$package_lock_backup"
cp "$gemfile_lock" "$gemfile_lock_backup"
# shellcheck disable=SC2329
cleanup() {
  set +e
  if [[ -d "$harness" && -d "$artifacts" ]]; then
    python3 "$harness/scripts/redact_artifacts.py" "$artifacts" >/dev/null 2>&1 || true
  fi
  if [[ "$installed_app" == true && "${CIO_E2E_KEEP_APP:-false}" != "true" ]]; then
    xcrun simctl terminate "$device_id" "$APP_ID" >/dev/null 2>&1 || true
    xcrun simctl uninstall "$device_id" "$APP_ID" >/dev/null 2>&1 || true
  fi
  if [[ "$simulator_started_by_runner" == true ]]; then
    xcrun simctl shutdown "$device_id" >/dev/null 2>&1 || true
  fi
  if [[ "$nse_env_generated" == true ]]; then
    if [[ -f "$nse_env_backup" ]]; then
      cp "$nse_env_backup" "$nse_env"
    else
      rm -f -- "$nse_env"
    fi
  fi
  cp "$package_lock_backup" "$package_lock"
  cp "$gemfile_lock_backup" "$gemfile_lock"
  case "$run_root" in
    "$temp_base"/cio-rn-remote-push.*) rm -rf -- "$run_root" ;;
  esac
}
trap cleanup EXIT

ruby "$MAESTRO_DIR/configure_nse_env.rb" \
  "$app_env" \
  "$SAMPLE_ROOT/ios/NotificationServiceExtension/Env.swift.sample" \
  "$run_root/Env.swift.generated"
if [[ -f "$nse_env" ]]; then
  cp "$nse_env" "$nse_env_backup"
fi
nse_env_generated=true
cp "$run_root/Env.swift.generated" "$nse_env"

IOS_CDP_API_KEY="$(ruby -e 'print File.read(ARGV[0])[/CDP_API_KEY\s*=\s*"([^"]+)"/, 1].to_s' "$run_root/Env.swift.generated")"
IOS_SITE_ID="$(ruby -e '
  text = File.read(ARGV[0])
  primary = text[/primary:\s*\{(.*?)\}\s+satisfies/m, 1].to_s
  print primary[/SITE_ID:\s*'"'"'([^'"'"']+)'"'"'/, 1].to_s
' "$app_env")"
[[ -n "$IOS_CDP_API_KEY" && -n "$IOS_SITE_ID" ]] || die "APN sample redaction values could not be resolved"
export IOS_CDP_API_KEY IOS_SITE_ID

git init -q "$harness"
git -C "$harness" remote add origin https://github.com/customerio/mobile-e2e.git
git -C "$harness" fetch -q --depth 1 origin "$MOBILE_E2E_REF"
git -C "$harness" checkout -q --detach FETCH_HEAD
[[ "$(git -C "$harness" rev-parse HEAD)" == "$MOBILE_E2E_REF" ]] || die "mobile-e2e harness checkout does not match the reviewed commit"
cp "$MAESTRO_DIR/remote_push.yaml" "$harness/flows/reactnative_remote_push.yaml"

cd "$REPO_ROOT"
npm ci
cd "$SAMPLE_ROOT"
bundle install
npm run ci:install_ios

xcodebuild -quiet \
  -workspace ios/SampleApp.xcworkspace \
  -scheme SampleApp \
  -configuration Release \
  -destination "platform=iOS Simulator,id=$device_id" \
  -derivedDataPath "$derived_data" \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGNING_REQUIRED=YES \
  build >"$run_root/xcodebuild.log" 2>&1 || {
    if ruby -e '
      key = ENV.fetch("IOS_CDP_API_KEY")
      site_id = ENV.fetch("IOS_SITE_ID")
      path = ARGV[0]
      redacted = File.read(path).gsub(key, "[REDACTED]").gsub(site_id, "[REDACTED]")
      File.write(path, redacted)
    ' "$run_root/xcodebuild.log"; then
      tail -100 "$run_root/xcodebuild.log" >&2
    else
      echo "React Native APN sample build failed; log withheld because credential redaction failed" >&2
    fi
    die "React Native APN sample build failed"
  }
echo "React Native APN sample build succeeded"

app_path="$derived_data/Build/Products/Release-iphonesimulator/SampleApp.app"
[[ -d "$app_path" ]] || die "built sample app was not found at $app_path"
simulator_entitlements="$derived_data/Build/Intermediates.noindex/SampleApp.build/Release-iphonesimulator/SampleApp.build/SampleApp.app-Simulated.xcent"
[[ -f "$simulator_entitlements" ]] || die "built sample app simulator entitlements were not found"
[[ "$(plutil -extract aps-environment raw "$simulator_entitlements")" == "development" ]] || \
  die "built sample app is missing the development APNs simulator entitlement"
xcrun simctl uninstall "$device_id" "$APP_ID" >/dev/null 2>&1 || true
xcrun simctl install "$device_id" "$app_path"
installed_app=true

mkdir -p "$artifacts"
set +e
maestro --device "$device_id" test \
  --debug-output "$artifacts" \
  --flatten-debug-output \
  -e "APP_ID=$APP_ID" \
  -e "MAESTRO_APP_API_KEY=$MAESTRO_APP_API_KEY" \
  -e "MAESTRO_EXT_API_BASE_URL=$MAESTRO_EXT_API_BASE_URL" \
  "$harness/flows/reactnative_remote_push.yaml"
result=$?
set -e

python3 "$harness/scripts/redact_artifacts.py" "$artifacts"
python3 "$harness/scripts/redact_artifacts.py" "$artifacts" --check
if [[ -n "$artifact_export_dir" ]]; then
  mkdir -p "$artifact_export_dir"
  cp -R "$artifacts/." "$artifact_export_dir/"
fi
exit "$result"
