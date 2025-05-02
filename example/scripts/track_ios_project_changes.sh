#!/bin/bash

# If you change the untracked xcode project file and want to
# preserve the changes, you need to run this script.
#
# Invoking it will de-integrate cocoapods to ensure the untracked
# xcode project file contains only the changes you made.
# then it will replace the ios/SampleApp.xcodeproj.tracked
# with the untracked one at ios/SampleApp.xcodeproj.
# After that, you will need to rerun `bundle exec pod install` to
# re-integrate cocoapods if you want to keep using it.
#
# Use script: ./scripts/track_ios_project_changes.sh

set -e

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
EXAMPLES_DIR="$(cd "$SCRIPTS_DIR/.." &>/dev/null && pwd)"

cd "$EXAMPLES_DIR/ios"

# De-integrate cocoapods
bundle exec pod deintegrate
echo "✅ De-integrated cocoapods"

# Replace the tracked xcode project file with the untracked one
rm -rf SampleApp.xcodeproj.tracked
cp -R SampleApp.xcodeproj SampleApp.xcodeproj.tracked
echo "✅ Copied untracked xcode project file to tracked one"
echo "Please review the changes in ios/SampleApp.xcodeproj.tracked"
