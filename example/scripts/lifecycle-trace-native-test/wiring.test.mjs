import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {readFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import test from 'node:test';

const testDirectory = path.dirname(fileURLToPath(import.meta.url));
const repositoryRoot = path.resolve(testDirectory, '../../..');
const appDelegatePath = path.join(repositoryRoot, 'example/ios/SampleApp/AppDelegate.swift');
const projectPath = path.join(
  repositoryRoot,
  'example/ios/SampleApp.xcodeproj.tracked/project.pbxproj'
);
const appDelegate = readFileSync(appDelegatePath, 'utf8');
const project = readFileSync(projectPath, 'utf8');

function occurrences(source, needle) {
  return source.split(needle).length - 1;
}

test('configures exactly one native Swift trace stream', () => {
  assert.equal(occurrences(appDelegate, 'LifecycleTraceHarness.configureFromEnvironment('), 1);
  assert.equal(occurrences(appDelegate, 'LifecycleTraceHarness.startScenario()'), 1);
  assert.match(appDelegate, /LifecycleTracePlatformProbeObserver\(\)/);
  assert.doesNotMatch(appDelegate, /cioFixtureTrace|LifecycleTrace\.attach|runtime:\s*\.javascript/);
});

test('keeps the killed-state shadow workaround and original React Native properties', () => {
  const shadowBlock = `    let remotePush = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [String: [String: [String: String]]]
    if let link = remotePush?["CIO"]?["push"]?["link"], let url = URL(string:link) {
      var launchOptions = launchOptions ?? [:]
      if launchOptions[UIApplication.LaunchOptionsKey.url] == nil {
        launchOptions[UIApplication.LaunchOptionsKey.url] = url
      }
    }`;
  assert.ok(appDelegate.includes(shadowBlock));
  assert.match(appDelegate, /initialProperties: \["appName": appName\]/);
  assert.doesNotMatch(appDelegate, /initialProperties:[^\n]*CIO_LIFECYCLE|cioFixtureTrace/);
});

test('instruments only existing application and routing seats', () => {
  for (const callback of [
    '.applicationDidFinishLaunching',
    '.applicationOpenURL',
    '.applicationContinueUserActivity',
    '.hostRouteURL',
    '.hostRouteUserActivity',
    '.customerIORouteDeepLink',
  ]) {
    assert.ok(appDelegate.includes(callback), `missing ${callback}`);
  }
  assert.doesNotMatch(appDelegate, /UISceneDelegate|UNUserNotificationCenterDelegate/);
  assert.doesNotMatch(appDelegate, /rctJavaScript|wrapperAppReceived|appReceived/);
  assert.match(
    appDelegate,
    /LifecycleTraceHarness\.sharedRecorder\?\.scenario\.isColdStart == true/
  );
  assert.match(
    appDelegate,
    /LifecycleTraceEvidence\.isCustomerIOLiveActivityRoute\(url\)/
  );
});

test('wires each byte-copied shared support source exactly once', () => {
  const supportHashes = {
    'LifecycleTraceEvidence.swift':
      '9d9b644e73b54fec66a4ae91e516b747ae8d610b30cbb8706c441a153e6d8110',
    'LifecycleTraceModel.swift':
      'cd74c8b0c9ebdda75f5a3045e6ddbe6dc993252aeec7649b84c05c21c43f5ff1',
    'LifecycleTraceProbe.swift':
      '19d4bee544376fa5c3e95c6d1ad66b9c654a288bafdef5e45d99f1a0757e0783',
    'LifecycleTraceRecorder.swift':
      'd494411f8a4f286c679b67dae70f7df2ccbcb02882598e3b2a6219ebdf7c9af8',
  };
  for (const [file, expectedHash] of Object.entries(supportHashes)) {
    assert.equal(
      occurrences(project, `${file} in Sources`),
      2,
      `${file} must have one PBXBuildFile declaration and one sources entry`
    );
    assert.equal(
      occurrences(project, `path = Fixtures/${file}`),
      1,
      `${file} must have one fixture file reference`
    );
    const source = readFileSync(
      path.join(repositoryRoot, 'example/ios/SampleApp/Fixtures', file)
    );
    assert.equal(createHash('sha256').update(source).digest('hex'), expectedHash);
  }
});

test('does not modify JavaScript or the published iOS wrapper', () => {
  const changed = execFileSync(
    'git',
    [
      'status',
      '--porcelain=v1',
      '--untracked-files=all',
      '--',
      'example/index.js',
      'example/src',
      'ios',
    ],
    {cwd: repositoryRoot, encoding: 'utf8'}
  ).trim();
  assert.equal(changed, '');
});
