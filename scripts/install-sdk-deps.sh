set -e

# Installs Customer.IO React Native SDK either from npm (if version is provided) or from a local tarball (default).
# Usage: 
# cd apps/APN/ # make sure you run this script from the root directory of the sample app. 
# It's recommended to add this to the package.json of the sample app:
# "scripts": {
#   "install-sdk-deps": "CIO_PACKAGE_VERSION=$npm_config_cio_rn_sdk ../../scripts/install-sdk-deps.sh",
#   "preinstall": "npm run install-sdk-deps",
# }
# Then, you can run using either of the following methods:
# 1. Run manually with:
#    npm run install-sdk-deps                     # Installs from local tarball (default)
#    npm run install-sdk-deps --cio-rn-sdk=X.Y.Z  # Installs version X.Y.Z from npm
# 2. Automatically triggered via `npm install` when used in `preinstall`:
#    npm install                     # Installs from local tarball (default)
#    npm install --cio-rn-sdk=X.Y.Z  # Installs version X.Y.Z from npm
#
# Note: 
# This script assumes the sample app is using npm, not yarn. yarn has a caching 
# mechanism that makes it difficult to update the SDK from a local install. 
# https://github.com/yarnpkg/yarn/issues/5357 
#

# Define constants
PACKAGE_NAME="customerio-reactnative"
PACKAGE_PATH_RELATIVE=${1:-../..} # Default package path to `../..` if no argument is provided
TARBALL_NAME=$PACKAGE_NAME.tgz
TARBALL_PATTERN=$PACKAGE_NAME-*.tgz
START_DIR=$(pwd) # Save the current directory (starting directory)

echo "Running install-sdk-deps script..."
echo "Starting in directory: '$START_DIR' with relative package path: '$PACKAGE_PATH_RELATIVE'"

echo "Uninstalling existing package $PACKAGE_NAME to ensure given version is installed correctly..."
npm uninstall $PACKAGE_NAME --no-save

# If a specific version is provided, install directly from npm and skip tarball steps
if [[ -n "$CIO_PACKAGE_VERSION" ]]; then
  echo "$PACKAGE_NAME version is set to $CIO_PACKAGE_VERSION, skipping tarball steps and installing from npm..."
  npm install "$PACKAGE_NAME@$CIO_PACKAGE_VERSION" --save-exact
  echo "✅ $PACKAGE_NAME@$CIO_PACKAGE_VERSION installed successfully!"
  exit 0
fi

# If no specific version is provided, generate tarball for local install
# Navigate to root package directory
cd $PACKAGE_PATH_RELATIVE
echo "Running pre-deploy script to compile code. We run the same commands as we do for production deployments so QA testing in sample apps is more accurate to a production environment"
npm run pre-deploy
echo "Generating tarball for $PACKAGE_NAME...\n"
# Remove any existing matching tarball to avoid conflicts
rm $TARBALL_PATTERN || true
# Generate the tarball using npm pack
# This creates a tarball named based on the `name` and `version` fields in the package.json
npm pack --silent
# Rename the tarball to a consistent name
mv $TARBALL_PATTERN $TARBALL_NAME
echo -e "\n✅ Tarball created successfully: '$TARBALL_NAME' at '$(pwd)'"

# Return to the starting directory
cd $START_DIR
echo "Returned to directory: '$(pwd)'"

echo "Installing $PACKAGE_NAME from local path..."
npm install "$PACKAGE_PATH_RELATIVE/$TARBALL_NAME" --silent

echo "✅ $PACKAGE_NAME installed successfully as $TARBALL_NAME dependency!"
