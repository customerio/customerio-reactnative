const fs = require('fs');

function runPostInstall() {
  // set package.json file path
  const rnPJsonFile = `${__dirname}/../../package.json`;

  const expoVersion = require(`${__dirname}/../../../customerio-expo-plugin/package.json`);
  if (expoVersion) {
    const rnPJson = fs.readFileSync(rnPJsonFile, 'utf8');

    const rnPackage = JSON.parse(rnPJson);
    rnPackage.expoVersion = expoVersion.version;

    fs.writeFileSync(rnPJsonFile, JSON.stringify(rnPackage, null, 2));
  }
}

exports.runPostInstall = runPostInstall;
