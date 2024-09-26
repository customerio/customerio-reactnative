#!/bin/bash

# Script that updates the package.json file in the SDK to newest semantic version.
#
# Designed to be run from CI server or manually. 
# 
# Use script: ./scripts/update-version.sh "0.1.1"

set -e 

NEW_VERSION="$1"

# Update new version in package.json file
PACKAGE_JSON_SOURCE_FILE="package.json"
echo "Updating package.json at: $PACKAGE_JSON_SOURCE_FILE to new version: $NEW_VERSION"
npm version "$NEW_VERSION" --no-git-tag-version --allow-same-version
echo "Done! Showing changes to confirm:"
git diff $PACKAGE_JSON_SOURCE_FILE

# Update new version in customer_io_config.xml file
SDK_CONFIG_XML_FILE="android/src/main/res/values/customer_io_config.xml"
SDK_CONFIG_CLIENT_VERSION_KEY="customer_io_react_native_sdk_client_version"
echo "Updating customer_io_config.xml at: $SDK_CONFIG_XML_FILE to new version: $NEW_VERSION"
sd "<string name=\"$SDK_CONFIG_CLIENT_VERSION_KEY\">.*</string>" "<string name=\"$SDK_CONFIG_CLIENT_VERSION_KEY\">$NEW_VERSION</string>" $SDK_CONFIG_XML_FILE
echo "Done! Showing changes to confirm:"
git diff $SDK_CONFIG_XML_FILE
