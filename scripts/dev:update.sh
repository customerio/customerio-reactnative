set -e

# Updates the RN SDK in the sample app during SDK development. Great for testing changes to the SDK in the sample app.
#
# Usage: 
# cd apps/APN/ # make sure you run this script from the root directory of the sample app. 
# ../../scripts/dev:update.sh
# 
# It's recommended to add this to the package.json of the sample app:
# "scripts": {
#   "dev:update": "../../scripts/dev:update.sh"
# }
# Then, you can run `npm run dev:update` to be easier. 
#
# Note: 
# This script assumes the sample app is using npm, not yarn. yarn has a caching 
# mechanism that makes it difficult to update the SDK from a local install. 
# https://github.com/yarnpkg/yarn/issues/5357 

# change directory to where you are executing the script from, not the directory where the script is located in. 
RUNNING_DIRECTORY="$(pwd)"
cd "$RUNNING_DIRECTORY"

echo "Building RN SDK"
cd ../../ 
echo "Running pre-deploy script to compile code. We run the same commands as we do for production deployments so QA testing in sample apps is more accurate to a production environment"
npm run pre-deploy 

rm customerio-reactnative*.tgz || true # This is to prepare for the next step. Remove any existing .tgz files (from previous "npm pack" runs) so that the next command doesn't fail.
npm pack # npm packages SDK the same way that it does before deploying to production. The .tgz file that npm produces here is the same one that is uploaded to npmjs.com for production deployments. Our sample apps will install the local SDK from this .tgz file to immiate a production deployment.
mv customerio-reactnative-*.tgz customerio-reactnative.tgz # rename the .tgz file to a more predictable name. This is so our sample apps do not need to update the package.json file and can instead continue to use the same local file path for the "customerio-reactnative" package. 

cd "$RUNNING_DIRECTORY" # go back to the same apps directory to install the package that we just built. 

echo "Installing RN SDK"
# Update only the RN SDK because that's faster then updating all. 
# using --no-audit to make update faster. 
# using --verbose to find ways to make command run faster.
# Check if running in CI environment to use --package-lock-only to only update package-lock.json file.
if [ "$CI" = "true" ]; then
  echo "Running in CI, using --package-lock-only"
  npm update customerio-reactnative --verbose --no-audit --package-lock-only
else
  echo "Running locally, without --package-lock-only"
  npm update customerio-reactnative --verbose --no-audit
fi