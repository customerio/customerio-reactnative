const postInstall = `${__dirname}/../../customerio-expo-plugin/src/postInstallHelper.js`;

const ph = require(postInstall);

ph.runPostInstall();
