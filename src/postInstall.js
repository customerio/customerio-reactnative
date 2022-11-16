const fs = require('fs');

const filename = `${__dirname}/../../customerio-expo-plugin/package.json`;
const rnFile = `${__dirname}/../package.json`;

if (fs.existsSync(filename)) {
  try {
    const pJsonFile = fs.readFileSync(rnFile, 'utf8');
    const pJson = require(filename);
    const expoVersionSnippet = `"expoVersion": "${pJson.version}"`;
    const versionRegEx = new RegExp(expoVersionSnippet);

    const lines = pJsonFile.split('\n');
    const missingMmatch = pJsonFile.match(versionRegEx);
    const expoVersionRegex = /"expoVersion": ".*"/;
    const existatch = pJsonFile.match(expoVersionRegex);

    if (existatch && !missingMmatch) {
      const index = lines.findIndex((line) => expoVersionRegex.test(line));

      const content = [
        ...lines.slice(0, index),
        `  ${expoVersionSnippet},`,
        ...lines.slice(index + 1),
      ];

      fs.writeFileSync(rnFile, content.join('\n'), 'utf8');
    }
  } catch (error) {}
}
