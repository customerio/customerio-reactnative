const fs = require('fs');

function runPostInstall() {
  // set package.json file path
  const rnPJsonFile = `${__dirname}/../../package.json`;

  try {
    const expoVersion = require('customerio-expo-plugin/version');
    if (expoVersion) {
      const rnPJson = fs.readFileSync(rnPJsonFile, 'utf8');

      const rnPackage = JSON.parse(rnPJson);
      rnPackage.expoVersion = expoVersion.LIB_VERSION;
      console.log(rnPackage)
      fs.writeFileSync(rnPJsonFile, JSON.stringify(rnPackage, null, 2));
    }
  } catch (error) {
    console.log(error);
  } // do nothing if this operation fails
}

exports.runPostInstall = runPostInstall;
