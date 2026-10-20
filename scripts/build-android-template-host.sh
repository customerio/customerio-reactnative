#!/usr/bin/env bash
# Builds a stock React Native template app that depends on this package, to prove the Android
# module configures and compiles the way a customer's app builds it.
#
# Usage: scripts/build-android-template-host.sh <template-defaults|agp9-defaults>
#   template-defaults  build the app exactly as `@react-native-community/cli init` generates it.
#                      React Native 0.87+ templates opt out of AGP 9's built-in Kotlin and new DSL
#                      with android.builtInKotlin=false and android.newDsl=false.
#   agp9-defaults      turn both opt-outs on and drop the app's explicit Kotlin plugin, which is
#                      what AGP 9 defaults to and what AGP 10 will require (React Native 0.87+)
#
# Environment:
#   RN_VERSION           React Native and template version to generate (default 0.88.0)
#   RN_CLI_VERSION       @react-native-community/cli version that runs `init` (default 20.2.0)
#   CIO_PACKAGE_TARBALL  install this packed SDK instead of running `npm pack` on the checkout
#   CIO_HOST_PARENT      generate the host here and keep it, instead of in a temporary directory
#   ANDROID_ABI          single ABI to build (default x86_64, arm64-v8a on arm64 hosts)
#   GRADLE_TASK          Gradle task to run (default :app:assembleDebug). Use
#                        :customerio-reactnative:assembleDebug to compile only the module, for
#                        templates whose app can't build with this SDK as generated

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="CioAndroidHost"
RN_VERSION="${RN_VERSION:-0.88.0}"
RN_CLI_VERSION="${RN_CLI_VERSION:-20.2.0}"
GRADLE_TASK="${GRADLE_TASK:-:app:assembleDebug}"
MODULE_CLASS="io/customer/reactnative/sdk/CustomerIOReactNativePackage.class"

mode="${1:-}"
case "$mode" in
  template-defaults) built_in_kotlin=false ;;
  agp9-defaults) built_in_kotlin=true ;;
  *)
    echo "usage: $0 <template-defaults|agp9-defaults>" >&2
    exit 2
    ;;
esac

if [[ -z "${ANDROID_ABI:-}" ]]; then
  if [[ "$(uname -m)" == arm64 || "$(uname -m)" == aarch64 ]]; then
    ANDROID_ABI=arm64-v8a
  else
    ANDROID_ABI=x86_64
  fi
fi

if [[ -n "${CIO_HOST_PARENT:-}" ]]; then
  mkdir -p "$CIO_HOST_PARENT"
  host_parent="$(cd "$CIO_HOST_PARENT" && pwd)"
else
  host_parent="$(mktemp -d "${TMPDIR:-/tmp}/cio-rn-android-host.XXXXXX")"
  trap 'rm -rf "$host_parent"' EXIT
fi
host="$host_parent/$APP_NAME"
if [[ -e "$host" ]]; then
  echo "error: $host already exists; pick an empty CIO_HOST_PARENT" >&2
  exit 2
fi

if [[ -n "${CIO_PACKAGE_TARBALL:-}" ]]; then
  package="$(cd "$(dirname "$CIO_PACKAGE_TARBALL")" && pwd)/$(basename "$CIO_PACKAGE_TARBALL")"
else
  cd "$REPO_ROOT"
  npm ci
  package="$host_parent/$(npm pack --silent --pack-destination "$host_parent" | tail -n 1)"
fi

cd "$host_parent"
npx --yes "@react-native-community/cli@$RN_CLI_VERSION" init "$APP_NAME" \
  --version "$RN_VERSION" \
  --skip-install \
  --skip-git-init
cd "$host"
npm install
npm install "$package"

# Fail loudly if the template stops generating what a mode relies on, rather than silently
# building something other than what the mode names.
properties=android/gradle.properties
app_gradle=android/app/build.gradle
grep -qx 'newArchEnabled=true' "$properties"
if [[ "$mode" == agp9-defaults ]]; then
  grep -qx 'android.builtInKotlin=false' "$properties"
  grep -qx 'android.newDsl=false' "$properties"
  grep -qx 'apply plugin: "org.jetbrains.kotlin.android"' "$app_gradle"
  sed -i.bak \
    -e 's/^android\.builtInKotlin=false$/android.builtInKotlin=true/' \
    -e 's/^android\.newDsl=false$/android.newDsl=true/' \
    "$properties"
  sed -i.bak '/^apply plugin: "org\.jetbrains\.kotlin\.android"$/d' "$app_gradle"
  rm -f "$properties.bak" "$app_gradle.bak"
elif grep -qE '^android\.(builtInKotlin|newDsl)=true$' "$properties"; then
  echo "error: the template enables AGP 9 built-in Kotlin or the new DSL by default now;" \
    "template-defaults no longer covers the opted-out build" >&2
  exit 1
fi
echo "Building $APP_NAME (React Native $RN_VERSION, $mode, $ANDROID_ABI):"
grep -E '^android\.(builtInKotlin|newDsl)=' "$properties" || echo '(template sets no AGP 9 opt-outs)'

# Install the template's NDK up front when it is missing, rather than relying on AGP's
# on-demand download in the middle of the build.
ndk_version="$(sed -n 's/^ *ndkVersion *= *"\(.*\)"$/\1/p' android/build.gradle)"
sdk_root="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
sdkmanager="$sdk_root/cmdline-tools/latest/bin/sdkmanager"
if [[ -n "$ndk_version" && -n "$sdk_root" && ! -d "$sdk_root/ndk/$ndk_version" && -x "$sdkmanager" ]]; then
  "$sdkmanager" --install "ndk;$ndk_version" > /dev/null
fi

cd android
./gradlew --no-daemon --stacktrace "$GRADLE_TASK" -PreactNativeArchitectures="$ANDROID_ABI"

# Record what actually resolved: AGP 9 raises the template's Kotlin Gradle plugin version.
./gradlew --no-daemon -q buildEnvironment \
  | grep -oE '(com\.android\.tools\.build:gradle|org\.jetbrains\.kotlin:kotlin-gradle-plugin):[^ ]+( -> [^ ]+)?' \
  | sort -u || true

# Prove the module's Kotlin sources were compiled, whichever plugin compiled them. An app build
# leaves the module's compile classes jar; a module-only build leaves its debug AAR.
module_build="$host/node_modules/customerio-reactnative/android/build"
classes_jar="$(find "$module_build/intermediates" -path '*compile_library_classes_jar/debug*' \
  -name classes.jar -print -quit 2>/dev/null || true)"
debug_aar="$(find "$module_build/outputs/aar" -name '*-debug.aar' -print -quit 2>/dev/null || true)"
if [[ -z "$classes_jar" && -n "$debug_aar" ]]; then
  classes_jar="$host_parent/module-debug-classes.jar"
  unzip -p "$debug_aar" classes.jar > "$classes_jar"
fi
if [[ -z "$classes_jar" ]] || ! unzip -l "$classes_jar" "$MODULE_CLASS" > /dev/null; then
  echo "error: $MODULE_CLASS is missing from the customerio-reactnative debug classes" >&2
  find "$module_build" -name '*.jar' -o -name '*.aar' >&2 || true
  exit 1
fi
echo "customerio-reactnative compiled (android.builtInKotlin=$built_in_kotlin): ${debug_aar:-$classes_jar}"
