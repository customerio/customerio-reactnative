const { exec } = require('child_process');

export const getPackageVersion = (packageName) => {
  return new Promise((resolve, reject) => {
    exec(`npm list ${packageName} --json`, (error, stdout) => {
      if (error) {
        reject(error);
        return;
      }

      try {
        const packageInfo = JSON.parse(stdout);
        const packageVersion = packageInfo.dependencies[packageName].version;
        resolve(packageVersion);
      } catch (parseError) {
        reject(parseError);
      }
    });
  });
};
