# Sample apps 

# Getting started with the sample apps

Run the following commands for any of our sample apps to begin building them: 

```
# First, from the root directory of the React Native SDK project, run: 
yarn install

# Then, you can move into one of the sample app directories and install it's dependencies:
cd Apps/<app-name>/
npm run preinstall
npm install 
```

> Note: Running the `npm run preinstall` step is suggested as a workaround to [npm skipping `preinstall` before `install` is complete](https://github.com/npm/cli/issues/2660). 

When you make a modification to the React Native SDK, you can run `npm run dev:update` from a sample app directory to update the Customer.io React Native SDK code in that app.