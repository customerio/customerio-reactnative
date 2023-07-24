set -e -x

# Update the SDK in the sample app during SDK development. 
# Run this script from the root directory of the sample app. 

# check if yq is installed and suggest installing it not. 
if ! command -v yq &> /dev/null
then
    echo "CLI program, yq, not yet installed. This script requires it. Install it: brew install yq"
    exit
fi

# change directory to where you are executing the script. 
RUNNING_DIRECTORY="$(pwd)"
cd "$RUNNING_DIRECTORY"

# We need to generate a unique filename each time we build to trick yarn to skip cache.
# https://github.com/yarnpkg/yarn/issues/5357 
echo "Generating a unique file name for the package to trick yarn to skip cache."
UNIQUE_PACKAGE_NAME="customerio-reactnative-$(date "+%s").tgz"
echo "UNIQUE_PACKAGE_NAME: $UNIQUE_PACKAGE_NAME"

echo "Removing existing install of RN SDK"
rm -rf node_modules/customerio-reactnative

echo "Building RN SDK"
cd ../../ 
rm customerio-reactnative*.tgz || true # remove previous builds so that "mv" command renames the file we just created

# We are generating 
npm pack && mv customerio-reactnative-*.tgz "$UNIQUE_PACKAGE_NAME" 
cd "$RUNNING_DIRECTORY" # go back to the same apps directory to install the package

echo "Installing RN SDK"
yq -iP ".dependencies[\"customerio-reactnative\"] = \"file:../../$UNIQUE_PACKAGE_NAME\"" package.json -o json
yarn install

echo "Cleanup"
rm ../../$UNIQUE_PACKAGE_NAME