#!/usr/bin/env bash

# bump-native-sdk.sh
# -------------------
# Updates the fixed native SDK versions used by the React-Native wrapper.
#   • android   – updates android/gradle.properties
#   • ios       – updates package.json (which the podspec reads)
#   • both      – updates both files
#
# Usage: ./scripts/bump-native-sdk.sh <platform> <version>
# Example: ./scripts/bump-native-sdk.sh android 4.6.3
#
# The script is idempotent and safe to run locally or in CI.

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <platform> <version>" >&2
  echo "platform : android | ios | both" >&2
  exit 1
fi

PLATFORM="$1"
VERSION="$2"

case "$PLATFORM" in
  android|ios|both) ;;
  *)
    echo "Invalid platform: $PLATFORM (expected android, ios, or both)" >&2
    exit 2
    ;;
esac

# --- Android ---------------------------------------------------------------
if [[ "$PLATFORM" == "android" || "$PLATFORM" == "both" ]]; then
  FILE="android/gradle.properties"
  echo "Updating Android native SDK to $VERSION in $FILE"
  sed -i.bak "s/^customerio\.reactnative\.cioSDKVersionAndroid=.*/customerio.reactnative.cioSDKVersionAndroid=${VERSION}/" "$FILE"
  rm "$FILE.bak"
fi

# --- iOS -------------------------------------------------------------------
if [[ "$PLATFORM" == "ios" || "$PLATFORM" == "both" ]]; then
  echo "Updating iOS native SDK to $VERSION in package.json"
  tmpfile="$(mktemp)"
  jq --arg ver "= ${VERSION}" '.cioNativeiOSSdkVersion = $ver' package.json > "$tmpfile"
  mv "$tmpfile" package.json
fi

# Print diff summary (helpful locally)
git --no-pager diff --stat || true

echo "✅ Native SDK version(s) bumped successfully." 