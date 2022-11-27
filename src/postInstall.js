const fs = require('fs');

// set package.json file paths
const expoPJsonFile = `${__dirname}/../../customerio-expo-plugin/package.json`;
const rnPJsonFile = `${__dirname}/../package.json`;

// check if expo plugin is installed
if (fs.existsSync(expoPJsonFile)) {
  // try and catch to revent errors
  try {
    // read package.json file for current package
    const rnPJson = fs.readFileSync(rnPJsonFile, 'utf8');

    // import expo plugin's package.json
    const expoPJson = require(expoPJsonFile);

    const rnPackage = JSON.parse(rnPJson);
    rnPackage.expoVersion = expoPJson.version;

    fs.writeFileSync(rnPJsonFile, JSON.stringify(rnPackage, null, 2));
  } catch (error) {} // do nothing if this operation fails
}
