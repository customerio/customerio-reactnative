import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import test from 'node:test';

const testDirectory = path.dirname(fileURLToPath(import.meta.url));
const repositoryRoot = path.resolve(testDirectory, '../../..');
const appDelegatePath = path.join(
  repositoryRoot,
  'example/ios/SampleApp/AppDelegate.swift'
);
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
  assert.equal(
    occurrences(appDelegate, 'LifecycleTraceHarness.configureFromEnvironment('),
    1
  );
  assert.equal(
    occurrences(appDelegate, 'LifecycleTraceHarness.startScenario()'),
    1
  );
  assert.match(appDelegate, /LifecycleTracePlatformProbeObserver\(\)/);
  assert.doesNotMatch(
    appDelegate,
    /cioFixtureTrace|LifecycleTrace\.attach|runtime:\s*\.javascript/
  );
  const probe = readFileSync(
    path.join(
      repositoryRoot,
      'example/ios/SampleApp/Fixtures/LifecycleTraceProbe.swift'
    ),
    'utf8'
  );
  assert.match(probe, /value\("HOST_TOPOLOGY"\)/);
  assert.match(probe, /value\("ACTIVATION_OCCURRENCE_ID"\)/);
  assert.match(probe, /hostTopology: hostTopology/);
  assert.match(
    probe,
    /activationOccurrenceIdentity: activationOccurrenceIdentity/
  );
  assert.match(appDelegate, /environment\.keys\.contains\(where:/);
  assert.match(appDelegate, /\$0\.hasPrefix\("CIO_LIFECYCLE_"\)/);
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
  assert.doesNotMatch(
    appDelegate,
    /initialProperties:[^\n]*CIO_LIFECYCLE|cioFixtureTrace/
  );
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
  assert.doesNotMatch(
    appDelegate,
    /UISceneDelegate|UNUserNotificationCenterDelegate/
  );
  assert.doesNotMatch(
    appDelegate,
    /rctJavaScript|wrapperAppReceived|appReceived/
  );
  assert.match(
    appDelegate,
    /LifecycleTraceHarness\.sharedRecorder\?\.scenario\.isColdStart == true/
  );
  assert.match(
    appDelegate,
    /LifecycleTraceEvidence\.isCustomerIOLiveActivityRoute\(url\)/
  );
  assert.match(
    appDelegate,
    /LifecycleTraceEvidence\.isTraceableURLRoute\(url\)/
  );
  assert.match(appDelegate, /LifecycleTraceEvidence\.widgetRoutingResult\(/);
  assert.doesNotMatch(appDelegate, /liveActivityRoutingResult/);
  const evidence = readFileSync(
    path.join(
      repositoryRoot,
      'example/ios/SampleApp/Fixtures/LifecycleTraceEvidence.swift'
    ),
    'utf8'
  );
  assert.match(evidence, /static func isTraceableURLRoute\(_ url: URL\)/);
  assert.match(
    evidence,
    /static func widgetRoutingResult\(\s*original: URL,\s*destination: URL\?/s
  );
});

test('pins the native-owned contract sync tool', () => {
  const tool = readFileSync(
    path.join(repositoryRoot, 'scripts/ios27_lifecycle_contract.py')
  );
  assert.equal(
    createHash('sha256').update(tool).digest('hex'),
    '03c48a30b287c58e5b611388980928ea08eb91385b52ac5e4dbdb1d32a23db28'
  );
});

test('wires each byte-copied shared support source exactly once', () => {
  const supportHashes = {
    'LifecycleTraceEvidence.swift':
      'f0719e181d7e1ff0423703e86ca9bcc50a99e98111da99dd357fdf09f9ceef87',
    'LifecycleTraceModel.swift':
      '62d6d8c3b50635a1a5687e535df4b13606b57a71a0106b419bc274819cf6c46c',
    'LifecycleTraceProbe.swift':
      'b3cb7c92594f555f326dc6410de33e2528382258cd691cf3fb8f2619c9bce580',
    'LifecycleTraceRecorder.swift':
      '9000c4667164cbc8fd2d0f25d938a1182660a2b0bf400f9166e0d8d86f1e458f',
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
    assert.equal(
      createHash('sha256').update(source).digest('hex'),
      expectedHash
    );
  }
});

test('keeps the React Native control explicitly AppDelegate-only', () => {
  const info = readFileSync(
    path.join(repositoryRoot, 'example/ios/SampleApp/Info.plist'),
    'utf8'
  );
  assert.doesNotMatch(info, /UIApplicationSceneManifest/);
  assert.doesNotMatch(
    appDelegate,
    /UISceneDelegate|configurationForConnecting/
  );
});

test('does not modify JavaScript or the published iOS wrapper', (t) => {
  const baseRef = process.env.CIO_LIFECYCLE_BASE_REF;
  if (!baseRef) {
    t.skip('PR base is unavailable; content and hash assertions still ran');
    return;
  }
  const mergeBase = execFileSync('git', ['merge-base', baseRef, 'HEAD'], {
    cwd: repositoryRoot,
    encoding: 'utf8',
  }).trim();
  const changed = execFileSync(
    'git',
    [
      'diff',
      '--name-only',
      `${mergeBase}...HEAD`,
      '--',
      'example/index.js',
      'example/src',
      'ios',
    ],
    { cwd: repositoryRoot, encoding: 'utf8' }
  ).trim();
  assert.equal(changed, '');
  // This second check protects local reviewers; CI starts from a clean checkout.
  const dirty = execFileSync(
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
    { cwd: repositoryRoot, encoding: 'utf8' }
  ).trim();
  assert.equal(dirty, '');
});
