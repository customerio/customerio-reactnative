const { execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const repositoryRoot = path.resolve(__dirname, '..');
const exampleRoot = path.join(repositoryRoot, 'example');
const commandTimeout = 120_000;
const packageManifest = JSON.parse(
  fs.readFileSync(path.join(repositoryRoot, 'package.json'), 'utf8')
);
const packageName = packageManifest.name;
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
    maxBuffer: 32 * 1024 * 1024,
    timeout: commandTimeout,
  })
);
const customerIODependency = config.dependencies[packageName];
const actualPodspec = customerIODependency?.platforms?.ios?.podspecPath;
if (!actualPodspec) {
  throw new Error(
    `Expected React Native autolinking to expose an iOS podspecPath for ${packageName}`
  );
}
const expectedPodspec = path.join(
  repositoryRoot,
  'customerio-reactnative.podspec'
);
const podfile = fs.readFileSync(
  path.join(exampleRoot, 'ios', 'Podfile'),
  'utf8'
);

const packageArchiveOutput = JSON.parse(
  execFileSync(
    'npm',
    [
      'pack',
      '--dry-run',
      '--json',
      '--ignore-scripts',
      '--foreground-scripts=false',
    ],
    {
      cwd: repositoryRoot,
      encoding: 'utf8',
      maxBuffer: 32 * 1024 * 1024,
      timeout: commandTimeout,
    }
  )
);
if (!Array.isArray(packageArchiveOutput) || packageArchiveOutput.length !== 1) {
  const count = Array.isArray(packageArchiveOutput)
    ? packageArchiveOutput.length
    : 'a non-array result';
  throw new Error(
    `Expected npm pack --json to return exactly one package, got ${count}`
  );
}
const packageArchive = packageArchiveOutput[0];
if (!packageArchive.files || packageArchive.name !== packageName) {
  throw new Error(
    `Expected npm pack to describe ${packageName} with a files list, got ${packageArchive.name ?? 'an unnamed package'}`
  );
}
const packagedPaths = new Set(packageArchive.files.map((file) => file.path));
for (const requiredPath of [
  'ios/cocoapods_deployment_target.rb',
  'docs/cocoapods-deployment-target-normalization.md',
]) {
  if (!packagedPaths.has(requiredPath)) {
    throw new Error(`Expected npm package to include ${requiredPath}`);
  }
}

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

const cliConfigAppleManifest = require.resolve(
  '@react-native-community/cli-config-apple/package.json',
  { paths: [exampleRoot] }
);
const cliConfigAppleVersion = JSON.parse(
  fs.readFileSync(cliConfigAppleManifest, 'utf8')
).version;
const expectedCliConfigAppleVersion =
  packageManifest.devDependencies['@react-native-community/cli-config-apple'];
if (cliConfigAppleVersion !== expectedCliConfigAppleVersion) {
  throw new Error(
    `Expected example CLI config Apple ${expectedCliConfigAppleVersion}, got ${cliConfigAppleVersion}`
  );
}
const findPodspec = require(
  path.join(
    path.dirname(cliConfigAppleManifest),
    'build',
    'config',
    'findPodspec'
  )
).default;
const temporaryRoot = fs.mkdtempSync(
  path.join(os.tmpdir(), 'customerio-rn-autolinking-')
);

try {
  const consumerRoot = path.join(temporaryRoot, 'consumer');
  const installedPackageRoot = path.join(
    consumerRoot,
    'node_modules',
    'customerio-reactnative'
  );
  fs.mkdirSync(path.join(installedPackageRoot, 'ios'), { recursive: true });
  for (const podspec of [
    'customerio-reactnative.podspec',
    'customerio-reactnative-richpush.podspec',
  ]) {
    fs.copyFileSync(
      path.join(repositoryRoot, podspec),
      path.join(installedPackageRoot, podspec)
    );
  }
  fs.copyFileSync(
    path.join(repositoryRoot, 'package.json'),
    path.join(installedPackageRoot, 'package.json')
  );
  fs.copyFileSync(
    path.join(repositoryRoot, 'ios', 'cocoapods_deployment_target.rb'),
    path.join(installedPackageRoot, 'ios', 'cocoapods_deployment_target.rb')
  );

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

  const installedManifest = execFileSync(
    process.execPath,
    [
      '-e',
      'process.stdout.write(require.resolve("customerio-reactnative/package.json"))',
    ],
    {
      cwd: consumerRoot,
      encoding: 'utf8',
      maxBuffer: 32 * 1024 * 1024,
      timeout: commandTimeout,
    }
  );
  const installedHelper = path.join(
    path.dirname(installedManifest),
    'ios',
    'cocoapods_deployment_target.rb'
  );
  const consumerHelperSmoke = [
    "require 'open3'",
    'module Pod',
    '  module Executable',
    '    def self.execute_command(command, arguments)',
    '      stdout, stderr, status = Open3.capture3(command, *arguments)',
    '      abort(stderr) unless status.success?',
    '      stdout',
    '    end',
    '  end',
    'end',
    'def node_resolve(script)',
    "  Pod::Executable.execute_command('node', ['-p', \"require.resolve('#{script}', {paths: [process.argv[1]]})\", Dir.pwd]).strip",
    'end',
    "package_root = File.dirname(node_resolve('customerio-reactnative/package.json'))",
    "require File.join(package_root, 'ios', 'cocoapods_deployment_target')",
    "actual = CustomerIO::CocoaPodsDeploymentTarget.maximum('15.0', '15.1')",
    'abort("installed helper maximum returned #{actual.inspect}, expected \\"15.1\\"") unless actual == \'15.1\'',
  ].join('\n');
  execFileSync('ruby', ['-e', consumerHelperSmoke], {
    cwd: consumerRoot,
    stdio: ['ignore', 'pipe', 'inherit'],
    maxBuffer: 32 * 1024 * 1024,
    timeout: commandTimeout,
  });

  console.log(`Customer package discovery uses ${customerPodspec}`);
  console.log(`Customer package helper loads from ${installedHelper}`);
} finally {
  fs.rmSync(temporaryRoot, { recursive: true, force: true });
}
