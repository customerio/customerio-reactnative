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
      '1db44862654643a5feb6209a87e6f7980e8f723e734f713a2f2902812e3f6215',
    'LifecycleTraceModel.swift':
      'cd74c8b0c9ebdda75f5a3045e6ddbe6dc993252aeec7649b84c05c21c43f5ff1',
    'LifecycleTraceProbe.swift':
      'eceb1a3f70791c8f4163759019068abd5ccdd94bc91d217367a79606941858aa',
    'LifecycleTraceRecorder.swift':
      '5c3ecfb951ab957f1215b45e70cb5aeb358cf3c6b5335ff553e91a65d02b1588',
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
