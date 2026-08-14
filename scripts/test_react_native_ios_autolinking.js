const { execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const repositoryRoot = path.resolve(__dirname, '..');
const exampleRoot = path.join(repositoryRoot, 'example');
const reactNativeCli = path.join(
  exampleRoot,
  'node_modules',
  '.bin',
  'react-native'
);

const config = JSON.parse(
  execFileSync(reactNativeCli, ['config'], {
    cwd: exampleRoot,
    encoding: 'utf8',
  })
);
const actualPodspec =
  config.dependencies['customerio-reactnative'].platforms.ios.podspecPath;
const expectedPodspec = path.join(
  repositoryRoot,
  'customerio-reactnative.podspec'
);
const podfile = fs.readFileSync(
  path.join(exampleRoot, 'ios', 'Podfile'),
  'utf8'
);

if (
  !podfile.includes("require_relative '../../ios/cocoapods_deployment_target'")
) {
  throw new Error(
    'Expected the sample Podfile to load deployment-target tooling from the current checkout'
  );
}

if (actualPodspec !== expectedPodspec) {
  throw new Error(
    `Expected Customer.io autolinking to use ${expectedPodspec}, got ${actualPodspec}`
  );
}

console.log(`Customer.io iOS autolinking uses ${actualPodspec}`);

const findPodspec = require(
  path.join(
    path.dirname(
      require.resolve('@react-native-community/cli-config-apple/package.json')
    ),
    'build',
    'config',
    'findPodspec'
  )
).default;
const temporaryRoot = fs.mkdtempSync(
  path.join(os.tmpdir(), 'customerio-rn-autolinking-')
);

try {
  const installedPackageRoot = path.join(
    temporaryRoot,
    'customerio-reactnative'
  );
  fs.mkdirSync(installedPackageRoot);
  for (const podspec of [
    'customerio-reactnative.podspec',
    'customerio-reactnative-richpush.podspec',
  ]) {
    fs.copyFileSync(
      path.join(repositoryRoot, podspec),
      path.join(installedPackageRoot, podspec)
    );
  }

  const customerPodspec = findPodspec(installedPackageRoot);
  const expectedCustomerPodspec = path.join(
    installedPackageRoot,
    'customerio-reactnative.podspec'
  );
  if (customerPodspec !== expectedCustomerPodspec) {
    throw new Error(
      `Expected an installed Customer.io package to use ${expectedCustomerPodspec}, got ${customerPodspec}`
    );
  }

  console.log(`Customer package discovery uses ${customerPodspec}`);
} finally {
  fs.rmSync(temporaryRoot, { recursive: true, force: true });
}
