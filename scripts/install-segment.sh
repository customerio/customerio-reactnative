#!/bin/sh

# Goal- compile the segment source code so our project can use it. 
# npm/yarn can get confused by what package.json file to use and what npm dependencies to use. 
# To fix that issue, we need to make the parent directory's package.json file invisible to npm/yarn
# and delete the node_modules directory after we are done compiling this code. 

mv package.json package.json-ignore
cd segment
yarn install --frozen-lockfile
yarn run build 
rm -rf node_modules
cd ../
mv package.json-ignore package.json