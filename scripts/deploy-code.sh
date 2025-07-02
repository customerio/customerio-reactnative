#!/bin/bash

# Script that uploads the npm package to npmjs. 
#
# Designed to be run from CI server or manually. 
# 
# Use script: ./scripts/deploy-code.sh

set -e 

# version in package.json has already been updated when the git tag was made. 
# we just need to push. 

if [[ "$IS_PRERELEASE" == "" ]]; then # makes sure it's determined if prerelease or not. 
    echo "Forgot to set environment variable IS_PRERELEASE. Value is \"false\" if deploying to production. Otherwise, set to \"true\"."
    echo "Set variable with command (yes, with the double quotes around the variable value): export NAME_OF_VAR=\"foo\""
    exit 1
fi

echo "Deploying npm package. Is pre-release: $IS_PRERELEASE"

if [[ "$NPM_TOKEN" == "" ]]; then # makes sure auth token is set. 
    echo "Forgot to set environment variable NPM_TOKEN (value found in 1password for Ami npm account). Set it, then try again."
    echo "Set variable with command (yes, with the double quotes around the variable value): export NAME_OF_VAR=\"foo\""
    exit 1
fi 

echo "Setting up configuration file that will authenticate your computer with npm server..."

NPM_CONFIG_FILE_PATH="$(npm config get userconfig)"
if [[ "$NPM_CONFIG_FILE_PATH" == "" ]]; then # makes sure auth token is set. 
    NPM_CONFIG_FILE_PATH="~/.npmrc"
fi 

echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" > "$NPM_CONFIG_FILE_PATH"

echo "Testing authentication. This next command should not fail and should print the username of the npm Ami account..."
npm whoami
echo "Authentication complete."

echo "Performing an install to make sure that all dependencies are installed"
npm ci
echo "npm install done."

echo "Running pre-deploy script to compile code"
npm run pre-deploy
echo "pre-deploy step complete"

# npmjs registry dist-tag for the release. 
# "latest" is usually used for production. You can use whatever other value that you want for non-production builds. 
# https://docs.npmjs.com/cli/v9/commands/npm-dist-tag
PUBLISH_DIST_TAG="latest"
if [[ "$IS_PRERELEASE" == "true" || "$IS_PRERELEASE" == true ]]; then 
    PUBLISH_DIST_TAG="next" # common pattern to see for npm packages is to use next for non-production builds. 
fi 

echo "Publishing npm package... with tag: $PUBLISH_DIST_TAG"

npm publish --tag $PUBLISH_DIST_TAG
echo "Publishing npm package complete"