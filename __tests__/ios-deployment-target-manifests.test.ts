import fs from 'node:fs';
import path from 'node:path';

describe('iOS deployment target manifests', () => {
  it('enforces iOS 15 without lowering React Native higher floors', () => {
    const repositoryRoot = path.resolve(__dirname, '..');
    const expectedManifests = new Set([
      'customerio-reactnative-richpush.podspec',
      'customerio-reactnative.podspec',
    ]);
    const discoveredManifests = new Set(
      fs
        .readdirSync(repositoryRoot)
        .filter((fileName) => fileName.endsWith('.podspec'))
    );

    expect(discoveredManifests).toEqual(expectedManifests);

    const expectedFloorDeclaration =
      'minimum_ios_version = [min_ios_version_supported, "15.0"]';

    for (const manifest of expectedManifests) {
      const contents = fs.readFileSync(
        path.join(repositoryRoot, manifest),
        'utf8'
      );
      expect(contents).toContain(expectedFloorDeclaration);
      expect(contents).toContain(
        '.map { |version| Pod::Version.new(version) }'
      );
      expect(contents).toContain('    .max');
      expect(contents).toContain(
        's.platforms    = { :ios => minimum_ios_version }'
      );
    }
  });
});
