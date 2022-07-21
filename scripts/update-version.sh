#!/bin/bash

# Script that updates the package.json file in the SDK to newest semantic version.
#
# Designed to be run from CI server or manually. 
# 
# Use script: ./scripts/update-version.sh "0.1.1"

set -e 

NEW_VERSION="$1"

echo "Updating package.json to new version: $NEW_VERSION"

npm version "$NEW_VERSION" --no-git-tag-version --allow-same-version

echo "Check package.json file. You should see version inside has been updated!"

cat package.json