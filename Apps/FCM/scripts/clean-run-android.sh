#!/bin/sh

# Script that clean install react native dependencies and run android app.
#
# Use script: ./scripts/clean-run-android.sh

# OR - To run on a specific device
# Use script: ./scripts/clean-run-android.sh DEVICE_ID

set -e

DEVICE_ID=$1

source ./scripts/clean-install-dependencies.sh

if [ ! -z "$DEVICE_ID" -a "$DEVICE_ID" != " " ]; then
    echo "\nRunning android app on $DEVICE_ID"
    npx react-native run-android --deviceId=$DEVICE_ID
else
    echo "\nRunning android app on default connected device"
    npx react-native run-android
fi
