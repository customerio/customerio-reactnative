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

    // set regular expression for expo version
    const expoVersionSnippet = `"expoVersion": "${expoPJson.version}"`;
    const versionRegEx = new RegExp(expoVersionSnippet);

    // split package.json lines into array
    const lines = rnPJson.split('\n');

    const missingMmatch = rnPJson.match(versionRegEx);
    const expoVersionRegex = /"expoVersion": ".*"/;
    const existatch = rnPJson.match(expoVersionRegex);

    // check if expoVersion key exists in current package and it has not been set already
    if (existatch && !missingMmatch) {
      const index = lines.findIndex((line) => expoVersionRegex.test(line));

      // set react native SDK expoVersion to current version in expo plugin package
      const content = [
        ...lines.slice(0, index),
        `  ${expoVersionSnippet},`,
        ...lines.slice(index + 1),
      ];

      // save react native SDK package.json file
      fs.writeFileSync(rnPJsonFile, content.join('\n'), 'utf8');
    }
  } catch (error) {} // do nothing if this operation fails
}
