#!/bin/bash

REPO_NAME=$1
NEW_TAG=$2

if [ "$REPO_NAME" == "Shahroz16/Item-catalog" ]; then
    sed -i "s/customerio.reactnative.cioSDKVersionAndroid=.*/customerio.reactnative.cioSDKVersionAndroid=$NEW_TAG/" android/gradle.properties
elif [ "$REPO_NAME" == "customerio-ios" ]; then
    jq '.cioNativeiOSSdkVersion = $newVersion' --arg newVersion "$NEW_TAG" package.json > package.tmp.json && mv package.tmp.json package.json
else
    echo "Unknown repository name: $REPO_NAME"
    exit 1
fi
