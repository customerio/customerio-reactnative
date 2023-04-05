#!/bin/sh

# Script that clean install react native dependencies and run ios app.
#
# Use script: ./scripts/clean-run-ios.sh

# OR - To run on a specific device
# Use script: ./scripts/clean-run-ios.sh DEVICE_NAME

set -e

DEVICE_NAME="$1"

source ./scripts/clean-install-dependencies.sh

if [ ! -z "$DEVICE_NAME" -a "$DEVICE_NAME" != " " ]; then
    echo "\nRunning ios app on $DEVICE_NAME"
    npx react-native run-ios --device "$DEVICE_NAME"
else
    echo "\nRunning ios app on default device"
    npx react-native run-ios
fi
