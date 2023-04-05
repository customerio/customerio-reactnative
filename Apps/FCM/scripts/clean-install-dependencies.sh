#!/bin/sh

# Script that removes node_modules and reinstall dependencies to remove any cached changes.
#
# Use script: ./scripts/clean-install-dependencies.sh

set -e

echo "\nRemoving node_modules"

rm -rf node_modules

echo "\nInstalling react native dependencies"

yarn install

echo "\nSuccessfully installed dependencies"
