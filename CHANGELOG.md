## [3.1.11](https://github.com/customerio/customerio-reactnative/compare/3.1.10...3.1.11) (2023-09-28)


### Bug Fixes

* stack-overflow caused by BQ recursion ([#204](https://github.com/customerio/customerio-reactnative/issues/204)) ([49dba31](https://github.com/customerio/customerio-reactnative/commit/49dba318d9706f50005ccd16aeab3f99d6ad044b))

### [3.1.10](https://github.com/customerio/customerio-reactnative/compare/3.1.9...3.1.10) (2023-09-07)


### Bug Fixes

* concurrency issue in-app ([#197](https://github.com/customerio/customerio-reactnative/issues/197)) ([eb2d1fb](https://github.com/customerio/customerio-reactnative/commit/eb2d1fbff2fb17f9b3569f4b843817991de3de7c))

### [3.1.9](https://github.com/customerio/customerio-reactnative/compare/3.1.8...3.1.9) (2023-09-05)


### Bug Fixes

* added url path encoding ([#194](https://github.com/customerio/customerio-reactnative/issues/194)) ([cd83f4b](https://github.com/customerio/customerio-reactnative/commit/cd83f4bb42160964d53c05c9afa58888791b0f92))

### [3.1.8](https://github.com/customerio/customerio-reactnative/compare/3.1.7...3.1.8) (2023-08-28)


### Bug Fixes

* include required messagingpush dependency for no push configuration ([#187](https://github.com/customerio/customerio-reactnative/issues/187)) ([78bbc63](https://github.com/customerio/customerio-reactnative/commit/78bbc63035743714c9fc6a3ad7ad046312e20ca6))

### [3.1.7](https://github.com/customerio/customerio-reactnative/compare/3.1.6...3.1.7) (2023-07-26)


### Bug Fixes

* support json array in attributes ([#180](https://github.com/customerio/customerio-reactnative/issues/180)) ([eb667a6](https://github.com/customerio/customerio-reactnative/commit/eb667a6d70a6a23afda440b42b357f07af00f07b))

### [3.1.6](https://github.com/customerio/customerio-reactnative/compare/3.1.5...3.1.6) (2023-07-24)


### Bug Fixes

* in-app messages not displaying for release builds on Android ([#174](https://github.com/customerio/customerio-reactnative/issues/174)) ([973d1cc](https://github.com/customerio/customerio-reactnative/commit/973d1cc811c178c75e50a0016342b0e8bc066114))

### [3.1.5](https://github.com/customerio/customerio-reactnative/compare/3.1.4...3.1.5) (2023-07-21)


### Bug Fixes

* sdk ignores requests when initializing the SDK from react native and from native iOS ([#173](https://github.com/customerio/customerio-reactnative/issues/173)) ([8bc7beb](https://github.com/customerio/customerio-reactnative/commit/8bc7beb338869bd69eb06f60f8f101a8106ee9dc))

### [3.1.4](https://github.com/customerio/customerio-reactnative/compare/3.1.3...3.1.4) (2023-07-20)


### Bug Fixes

* deinit cleanup repo bad memory access ([#171](https://github.com/customerio/customerio-reactnative/issues/171)) ([25f10b1](https://github.com/customerio/customerio-reactnative/commit/25f10b1c07796cb8931b9865bb05ee2d10cffe3f))

### [3.1.3](https://github.com/customerio/customerio-reactnative/compare/3.1.2...3.1.3) (2023-07-14)


### Bug Fixes

* hardcode android native SDK version ([#167](https://github.com/customerio/customerio-reactnative/issues/167)) ([be03bd5](https://github.com/customerio/customerio-reactnative/commit/be03bd5dfff7fdf142958c8ddf5f2f9c1ad21e2b))

### [3.1.2](https://github.com/customerio/customerio-reactnative/compare/3.1.1...3.1.2) (2023-07-12)


### Bug Fixes

* gist migration and crash fix ([#165](https://github.com/customerio/customerio-reactnative/issues/165)) ([01a3074](https://github.com/customerio/customerio-reactnative/commit/01a3074b2e7f1897b55d4e28b825e849e7e1e693))

### [3.1.1](https://github.com/customerio/customerio-reactnative/compare/3.1.0...3.1.1) (2023-07-10)


### Bug Fixes

* iOS bad memory access crash ([#164](https://github.com/customerio/customerio-reactnative/issues/164)) ([55b72a7](https://github.com/customerio/customerio-reactnative/commit/55b72a7d128b97eed4577a73132e7c8d32423cd5))

## [3.1.0](https://github.com/customerio/customerio-reactnative/compare/3.0.0...3.1.0) (2023-07-05)


### Features

* tracking push metrics from js ([#152](https://github.com/customerio/customerio-reactnative/issues/152)) ([6f51703](https://github.com/customerio/customerio-reactnative/commit/6f5170375498142f557870fdbb11104e91a74b83))

## [3.0.0](https://github.com/customerio/customerio-reactnative/compare/2.5.1...3.0.0) (2023-07-03)


### ⚠ BREAKING CHANGES

* auto-update native SDK and easier rich push install (#149)

### Bug Fixes

* auto-update native SDK and easier rich push install ([#149](https://github.com/customerio/customerio-reactnative/issues/149)) ([7e56d1e](https://github.com/customerio/customerio-reactnative/commit/7e56d1e95752fe267b286e9e52b1d11cf0c2fd12))

### [2.5.1](https://github.com/customerio/customerio-reactnative/compare/2.5.0...2.5.1) (2023-07-03)


### Bug Fixes

* android opened metrics when app in background ([#156](https://github.com/customerio/customerio-reactnative/issues/156)) ([fb14cce](https://github.com/customerio/customerio-reactnative/commit/fb14ccee755fefa004a4a55e7083d8d237f0a3b8))

## [2.5.0](https://github.com/customerio/customerio-reactnative/compare/2.4.2...2.5.0) (2023-06-28)


### Features

* delete device token from profile ([#158](https://github.com/customerio/customerio-reactnative/issues/158)) ([0ff0eac](https://github.com/customerio/customerio-reactnative/commit/0ff0eac9e4ef44f9342cadc3b5669da3ec94e7e1))

### [2.4.2](https://github.com/customerio/customerio-reactnative/compare/2.4.1...2.4.2) (2023-06-06)


### Bug Fixes

* update import from common to CioInternalCommon ([#147](https://github.com/customerio/customerio-reactnative/issues/147)) ([f0382a4](https://github.com/customerio/customerio-reactnative/commit/f0382a4823986be78680ce2dab468b2ea47d66fd))

### [2.4.1](https://github.com/customerio/customerio-reactnative/compare/2.4.0...2.4.1) (2023-06-05)


### Bug Fixes

* installation breaks due to lefthook in postinstall ([#144](https://github.com/customerio/customerio-reactnative/issues/144)) ([e451443](https://github.com/customerio/customerio-reactnative/commit/e451443c655c7c7c2882778cc4bf05020107196a))

## [2.4.0](https://github.com/customerio/customerio-reactnative/compare/2.3.3...2.4.0) (2023-06-01)


### Features

* dismiss in-app message ([#138](https://github.com/customerio/customerio-reactnative/issues/138)) ([55d4c62](https://github.com/customerio/customerio-reactnative/commit/55d4c6245b57a7090e0c0157996d2f43874b5297))

### [2.3.3](https://github.com/customerio/customerio-reactnative/compare/2.3.2...2.3.3) (2023-05-03)


### Bug Fixes

* autoupdate to latest major version of iOS SDK ([#124](https://github.com/customerio/customerio-reactnative/issues/124)) ([7904c50](https://github.com/customerio/customerio-reactnative/commit/7904c5079df06776e603b9741bd8831170724041))

### [2.3.2](https://github.com/customerio/customerio-reactnative/compare/2.3.1...2.3.2) (2023-04-20)


### Bug Fixes

* push opened metrics tracked on Android 12 ([#119](https://github.com/customerio/customerio-reactnative/issues/119)) ([dfd6fbd](https://github.com/customerio/customerio-reactnative/commit/dfd6fbdc1131b4f0f226480ef0ab8d67b16d4837))

### [2.3.1](https://github.com/customerio/customerio-reactnative/compare/2.3.0...2.3.1) (2023-04-20)


### Bug Fixes

* typescript definition for optional data attributes ([#51](https://github.com/customerio/customerio-reactnative/issues/51)) ([4cec62a](https://github.com/customerio/customerio-reactnative/commit/4cec62abcf45f14f060d60fb2239c94d50f0a9a9))

## [2.3.0](https://github.com/customerio/customerio-reactnative/compare/2.2.1...2.3.0) (2023-04-04)


### Features

* process push notifications received outside CIO SDK ([#117](https://github.com/customerio/customerio-reactnative/issues/117)) ([458472d](https://github.com/customerio/customerio-reactnative/commit/458472db12a0e7fa85ed920dc6810bd9697b0902))

### [2.2.1](https://github.com/customerio/customerio-reactnative/compare/2.2.0...2.2.1) (2023-03-28)


### Bug Fixes

* native push permission status match typescript enum value ([#118](https://github.com/customerio/customerio-reactnative/issues/118)) ([38b7349](https://github.com/customerio/customerio-reactnative/commit/38b7349fbf06dfae16e374bdae7e0780dc153c01))

## [2.2.0](https://github.com/customerio/customerio-reactnative/compare/2.1.0...2.2.0) (2023-03-03)


### Features

* push permission prompt ([#101](https://github.com/customerio/customerio-reactnative/issues/101)) ([1abe9b3](https://github.com/customerio/customerio-reactnative/commit/1abe9b33f05d125e4180a77207fad23080774550))

## [2.1.0](https://github.com/customerio/customerio-reactnative/compare/2.0.1...2.1.0) (2023-02-23)


### Features

* deprecated organization id for in-app ([#71](https://github.com/customerio/customerio-reactnative/issues/71)) ([691f324](https://github.com/customerio/customerio-reactnative/commit/691f3240288672d59d915fa6998271591d4fef03))
* in-app event handler ([#89](https://github.com/customerio/customerio-reactnative/issues/89)) ([07e38f7](https://github.com/customerio/customerio-reactnative/commit/07e38f721acb7a613371c2fc3ac6872c3ea8cb38))


### Bug Fixes

* kotlin version in gradle props ([#96](https://github.com/customerio/customerio-reactnative/issues/96)) ([35dceb2](https://github.com/customerio/customerio-reactnative/commit/35dceb293b746845425e977df42e07959df8b60b))
* remove return from init ([#93](https://github.com/customerio/customerio-reactnative/issues/93)) ([d54174b](https://github.com/customerio/customerio-reactnative/commit/d54174bd48586b35033d18c90290e927f0fee970))
* update android sdk to range ([#94](https://github.com/customerio/customerio-reactnative/issues/94)) ([5a5a012](https://github.com/customerio/customerio-reactnative/commit/5a5a012d5c18eb25f54dd2211173ac948c75a989))

### [2.0.1](https://github.com/customerio/customerio-reactnative/compare/2.0.0...2.0.1) (2023-01-30)


### Bug Fixes

* add register device token ([f865261](https://github.com/customerio/customerio-reactnative/commit/f86526193267692f68291406a61b75c5c700b2b6))

## [2.0.0](https://github.com/customerio/customerio-reactnative/compare/1.0.0...2.0.0) (2023-01-18)


### ⚠ BREAKING CHANGES

* bumped ios version to 2.0.0

### Features

* expo user agent ([#49](https://github.com/customerio/customerio-reactnative/issues/49)) ([377300c](https://github.com/customerio/customerio-reactnative/commit/377300c76d1e8856908c0b231bb8cc2c4b51f97c))


### Bug Fixes

* added support for android sdk 3.2.0 ([c0407be](https://github.com/customerio/customerio-reactnative/commit/c0407bed6df4582be8646ed44662d80a5868ad17))
* bumped ios version to 2.0.0 ([95f74b9](https://github.com/customerio/customerio-reactnative/commit/95f74b9c5e25e7d60e688de11459c83e30b50ae6))
* for test case failure due to file path ([ce43198](https://github.com/customerio/customerio-reactnative/commit/ce431983f45dcb0503e248a36393fff6fb12db15))
* ios and android sdk version update ([28e9ad3](https://github.com/customerio/customerio-reactnative/commit/28e9ad37e93da5d29745068ae3a722d3a32c8460))
* ios sdk latest version ([66c4607](https://github.com/customerio/customerio-reactnative/commit/66c46075160001f30da8097062cd85898dd0c50d))
* support for expo client ([b641fd8](https://github.com/customerio/customerio-reactnative/commit/b641fd8b94ab023c8a3577dd47ebdf02e431a4d4))
* updated ios sdk to 1.2.2 ([6605d56](https://github.com/customerio/customerio-reactnative/commit/6605d563fe28fae7464d336c2673bb8620fdba5b))
* updating to latest iOS SDK version ([a9c90f0](https://github.com/customerio/customerio-reactnative/commit/a9c90f0358e1500103a474ea93e912bd2b7d2804))

## [2.0.0-beta.1](https://github.com/customerio/customerio-reactnative/compare/1.0.0...2.0.0-beta.1) (2022-12-30)


### ⚠ BREAKING CHANGES

* bumped ios version to 2.0.0

### Features

* expo user agent ([#49](https://github.com/customerio/customerio-reactnative/issues/49)) ([377300c](https://github.com/customerio/customerio-reactnative/commit/377300c76d1e8856908c0b231bb8cc2c4b51f97c))


### Bug Fixes

* added support for android sdk 3.2.0 ([c0407be](https://github.com/customerio/customerio-reactnative/commit/c0407bed6df4582be8646ed44662d80a5868ad17))
* bumped ios version to 2.0.0 ([95f74b9](https://github.com/customerio/customerio-reactnative/commit/95f74b9c5e25e7d60e688de11459c83e30b50ae6))
* for test case failure due to file path ([ce43198](https://github.com/customerio/customerio-reactnative/commit/ce431983f45dcb0503e248a36393fff6fb12db15))
* ios and android sdk version update ([28e9ad3](https://github.com/customerio/customerio-reactnative/commit/28e9ad37e93da5d29745068ae3a722d3a32c8460))
* ios sdk latest version ([66c4607](https://github.com/customerio/customerio-reactnative/commit/66c46075160001f30da8097062cd85898dd0c50d))
* support for expo client ([b641fd8](https://github.com/customerio/customerio-reactnative/commit/b641fd8b94ab023c8a3577dd47ebdf02e431a4d4))
* updated ios sdk to 1.2.2 ([6605d56](https://github.com/customerio/customerio-reactnative/commit/6605d563fe28fae7464d336c2673bb8620fdba5b))
* updating to latest iOS SDK version ([a9c90f0](https://github.com/customerio/customerio-reactnative/commit/a9c90f0358e1500103a474ea93e912bd2b7d2804))

## [2.0.0-alpha.1](https://github.com/customerio/customerio-reactnative/compare/1.0.1-alpha.3...2.0.0-alpha.1) (2022-12-19)


### ⚠ BREAKING CHANGES

* bumped ios version to 2.0.0

### Features

* expo user agent ([#49](https://github.com/customerio/customerio-reactnative/issues/49)) ([377300c](https://github.com/customerio/customerio-reactnative/commit/377300c76d1e8856908c0b231bb8cc2c4b51f97c))


### Bug Fixes

* bumped ios version to 2.0.0 ([95f74b9](https://github.com/customerio/customerio-reactnative/commit/95f74b9c5e25e7d60e688de11459c83e30b50ae6))

### [1.0.1-alpha.3](https://github.com/customerio/customerio-reactnative/compare/1.0.1-alpha.2...1.0.1-alpha.3) (2022-12-01)


### Bug Fixes

* ios and android sdk version update ([28e9ad3](https://github.com/customerio/customerio-reactnative/commit/28e9ad37e93da5d29745068ae3a722d3a32c8460))

### [1.0.1-alpha.2](https://github.com/customerio/customerio-reactnative/compare/1.0.1-alpha.1...1.0.1-alpha.2) (2022-11-21)


### Bug Fixes

* added support for android sdk 3.2.0 ([c0407be](https://github.com/customerio/customerio-reactnative/commit/c0407bed6df4582be8646ed44662d80a5868ad17))
* for test case failure due to file path ([ce43198](https://github.com/customerio/customerio-reactnative/commit/ce431983f45dcb0503e248a36393fff6fb12db15))
* ios sdk latest version ([66c4607](https://github.com/customerio/customerio-reactnative/commit/66c46075160001f30da8097062cd85898dd0c50d))
* updated ios sdk to 1.2.2 ([6605d56](https://github.com/customerio/customerio-reactnative/commit/6605d563fe28fae7464d336c2673bb8620fdba5b))
* updating to latest iOS SDK version ([a9c90f0](https://github.com/customerio/customerio-reactnative/commit/a9c90f0358e1500103a474ea93e912bd2b7d2804))

### [1.0.1-alpha.1](https://github.com/customerio/customerio-reactnative/compare/1.0.0...1.0.1-alpha.1) (2022-10-31)


### Bug Fixes

* support for expo client ([b641fd8](https://github.com/customerio/customerio-reactnative/commit/b641fd8b94ab023c8a3577dd47ebdf02e431a4d4))

## 1.0.0 (2022-10-24)


### Features

* android updates in package ([#13](https://github.com/customerio/customerio-reactnative/issues/13)) ([b708fce](https://github.com/customerio/customerio-reactnative/commit/b708fcea40ae7a6586742fc39ec1c2e06eb7a559))
* android: package updates ([e87c6eb](https://github.com/customerio/customerio-reactnative/commit/e87c6eb05f5d357a626e982702dc1ff7171e4e09))
* android: setup config with initialization ([e915343](https://github.com/customerio/customerio-reactnative/commit/e915343be1e9967e3d3f5214b2ebcf313486c531))
* creating customerio react native package ([#1](https://github.com/customerio/customerio-reactnative/issues/1)) ([2d2bdae](https://github.com/customerio/customerio-reactnative/commit/2d2bdae0af337a488300e9196dcac07b058fe3d2))
* device attributes and other configurable properties ([#4](https://github.com/customerio/customerio-reactnative/issues/4)) ([bd79d96](https://github.com/customerio/customerio-reactnative/commit/bd79d96ecfd8724e979241d6f58324d26b5e1748))
* identify and clear user identity ([#2](https://github.com/customerio/customerio-reactnative/issues/2)) ([4430b66](https://github.com/customerio/customerio-reactnative/commit/4430b66fc6491a4ba7e1c571eb357a318366af3f))
* in-app functionality in react native package ([488c0c0](https://github.com/customerio/customerio-reactnative/commit/488c0c06b852a220c13c9bbffb3d5b254c7fb9ff))
* update package version ([8526a69](https://github.com/customerio/customerio-reactnative/commit/8526a6979405d19922a18f0bf281298b850f3e27))
* updated to android sdk 3.0.0-alpha.2 ([91978d7](https://github.com/customerio/customerio-reactnative/commit/91978d78cb5b10c90caeb088af2fc4f2a15e952b))
* updating ios sdk version in podspec ([1b1c26f](https://github.com/customerio/customerio-reactnative/commit/1b1c26fdedd14e837df2d117a6ab59a4916dc227))
* user-agent updates in package ([efff4fc](https://github.com/customerio/customerio-reactnative/commit/efff4fc30d3050e410b5e56cdd2464b7c2f6de41))


### Bug Fixes

* added support for android sdk 3.1.0 ([44a1b91](https://github.com/customerio/customerio-reactnative/commit/44a1b91c1ccdedecea526c09ff04654333137daa))
* change in way to update config in ios ([#15](https://github.com/customerio/customerio-reactnative/issues/15)) ([8680b28](https://github.com/customerio/customerio-reactnative/commit/8680b2850cf6f1823514ece8205ac8b354d17c04))
* initialized sdk from storage using context ([e3e609a](https://github.com/customerio/customerio-reactnative/commit/e3e609ae2fee6183050d993624bd4bd287a7ec97))
* push notifications integration ([#10](https://github.com/customerio/customerio-reactnative/issues/10)) ([5d7752d](https://github.com/customerio/customerio-reactnative/commit/5d7752d9732bd591be5153df6c5e46aed615bb04))
* updating gist dependency version ([9f8ac3f](https://github.com/customerio/customerio-reactnative/commit/9f8ac3f1d0ea0320d94f000a91b1bc482eba2b1d))


### Reverts

* update package version ([e02e6e5](https://github.com/customerio/customerio-reactnative/commit/e02e6e55cc569f1434efa523781e6805c27d4e2b))

## [1.0.0-beta.3](https://github.com/customerio/customerio-reactnative/compare/1.0.0-beta.2...1.0.0-beta.3) (2022-10-19)


### Bug Fixes

* added support for android sdk 3.1.0 ([44a1b91](https://github.com/customerio/customerio-reactnative/commit/44a1b91c1ccdedecea526c09ff04654333137daa))

## [1.0.0-beta.2](https://github.com/customerio/customerio-reactnative/compare/1.0.0-beta.1...1.0.0-beta.2) (2022-10-07)


### Bug Fixes

* updating gist dependency version ([9f8ac3f](https://github.com/customerio/customerio-reactnative/commit/9f8ac3f1d0ea0320d94f000a91b1bc482eba2b1d))

## 1.0.0-beta.1 (2022-09-15)


### Features

* android updates in package ([#13](https://github.com/customerio/customerio-reactnative/issues/13)) ([b708fce](https://github.com/customerio/customerio-reactnative/commit/b708fcea40ae7a6586742fc39ec1c2e06eb7a559))
* android: package updates ([e87c6eb](https://github.com/customerio/customerio-reactnative/commit/e87c6eb05f5d357a626e982702dc1ff7171e4e09))
* android: setup config with initialization ([e915343](https://github.com/customerio/customerio-reactnative/commit/e915343be1e9967e3d3f5214b2ebcf313486c531))
* creating customerio react native package ([#1](https://github.com/customerio/customerio-reactnative/issues/1)) ([2d2bdae](https://github.com/customerio/customerio-reactnative/commit/2d2bdae0af337a488300e9196dcac07b058fe3d2))
* device attributes and other configurable properties ([#4](https://github.com/customerio/customerio-reactnative/issues/4)) ([bd79d96](https://github.com/customerio/customerio-reactnative/commit/bd79d96ecfd8724e979241d6f58324d26b5e1748))
* identify and clear user identity ([#2](https://github.com/customerio/customerio-reactnative/issues/2)) ([4430b66](https://github.com/customerio/customerio-reactnative/commit/4430b66fc6491a4ba7e1c571eb357a318366af3f))
* in-app functionality in react native package ([488c0c0](https://github.com/customerio/customerio-reactnative/commit/488c0c06b852a220c13c9bbffb3d5b254c7fb9ff))
* update package version ([8526a69](https://github.com/customerio/customerio-reactnative/commit/8526a6979405d19922a18f0bf281298b850f3e27))
* updated to android sdk 3.0.0-alpha.2 ([91978d7](https://github.com/customerio/customerio-reactnative/commit/91978d78cb5b10c90caeb088af2fc4f2a15e952b))
* updating ios sdk version in podspec ([1b1c26f](https://github.com/customerio/customerio-reactnative/commit/1b1c26fdedd14e837df2d117a6ab59a4916dc227))
* user-agent updates in package ([efff4fc](https://github.com/customerio/customerio-reactnative/commit/efff4fc30d3050e410b5e56cdd2464b7c2f6de41))


### Bug Fixes

* change in way to update config in ios ([#15](https://github.com/customerio/customerio-reactnative/issues/15)) ([8680b28](https://github.com/customerio/customerio-reactnative/commit/8680b2850cf6f1823514ece8205ac8b354d17c04))
* initialized sdk from storage using context ([e3e609a](https://github.com/customerio/customerio-reactnative/commit/e3e609ae2fee6183050d993624bd4bd287a7ec97))
* push notifications integration ([#10](https://github.com/customerio/customerio-reactnative/issues/10)) ([5d7752d](https://github.com/customerio/customerio-reactnative/commit/5d7752d9732bd591be5153df6c5e46aed615bb04))


### Reverts

* update package version ([e02e6e5](https://github.com/customerio/customerio-reactnative/commit/e02e6e55cc569f1434efa523781e6805c27d4e2b))

## [1.0.0-alpha.6](https://github.com/customerio/customerio-reactnative/compare/1.0.0-alpha.5...1.0.0-alpha.6) (2022-09-13)


### Bug Fixes

* initialized sdk from storage using context ([e3e609a](https://github.com/customerio/customerio-reactnative/commit/e3e609ae2fee6183050d993624bd4bd287a7ec97))

## [1.0.0-alpha.5](https://github.com/customerio/customerio-reactnative/compare/1.0.0-alpha.4...1.0.0-alpha.5) (2022-09-01)


### Features

* android: setup config with initialization ([e915343](https://github.com/customerio/customerio-reactnative/commit/e915343be1e9967e3d3f5214b2ebcf313486c531))
* update package version ([8526a69](https://github.com/customerio/customerio-reactnative/commit/8526a6979405d19922a18f0bf281298b850f3e27))
* updated to android sdk 3.0.0-alpha.2 ([91978d7](https://github.com/customerio/customerio-reactnative/commit/91978d78cb5b10c90caeb088af2fc4f2a15e952b))
* updating ios sdk version in podspec ([1b1c26f](https://github.com/customerio/customerio-reactnative/commit/1b1c26fdedd14e837df2d117a6ab59a4916dc227))


### Reverts

* update package version ([e02e6e5](https://github.com/customerio/customerio-reactnative/commit/e02e6e55cc569f1434efa523781e6805c27d4e2b))

## [1.0.0-alpha.4](https://github.com/customerio/customerio-reactnative/compare/1.0.0-alpha.3...1.0.0-alpha.4) (2022-08-10)


### Features

* android: package updates ([e87c6eb](https://github.com/customerio/customerio-reactnative/commit/e87c6eb05f5d357a626e982702dc1ff7171e4e09))
* in-app functionality in react native package ([488c0c0](https://github.com/customerio/customerio-reactnative/commit/488c0c06b852a220c13c9bbffb3d5b254c7fb9ff))
* user-agent updates in package ([efff4fc](https://github.com/customerio/customerio-reactnative/commit/efff4fc30d3050e410b5e56cdd2464b7c2f6de41))

## [1.0.0-alpha.3](https://github.com/customerio/customerio-reactnative/compare/1.0.0-alpha.2...1.0.0-alpha.3) (2022-07-25)


### Features

* android updates in package ([#13](https://github.com/customerio/customerio-reactnative/issues/13)) ([b708fce](https://github.com/customerio/customerio-reactnative/commit/b708fcea40ae7a6586742fc39ec1c2e06eb7a559))


### Bug Fixes

* change in way to update config in ios ([#15](https://github.com/customerio/customerio-reactnative/issues/15)) ([8680b28](https://github.com/customerio/customerio-reactnative/commit/8680b2850cf6f1823514ece8205ac8b354d17c04))

## [1.0.0-alpha.2](https://github.com/customerio/customerio-reactnative/compare/1.0.0-alpha.1...1.0.0-alpha.2) (2022-06-28)


### Features

* device attributes and other configurable properties ([#4](https://github.com/customerio/customerio-reactnative/issues/4)) ([bd79d96](https://github.com/customerio/customerio-reactnative/commit/bd79d96ecfd8724e979241d6f58324d26b5e1748))


### Bug Fixes

* push notifications integration ([#10](https://github.com/customerio/customerio-reactnative/issues/10)) ([5d7752d](https://github.com/customerio/customerio-reactnative/commit/5d7752d9732bd591be5153df6c5e46aed615bb04))

## 1.0.0-alpha.1 (2022-06-23)


### Features

* creating customerio react native package ([#1](https://github.com/customerio/customerio-reactnative/issues/1)) ([2d2bdae](https://github.com/customerio/customerio-reactnative/commit/2d2bdae0af337a488300e9196dcac07b058fe3d2))
* identify and clear user identity ([#2](https://github.com/customerio/customerio-reactnative/issues/2)) ([4430b66](https://github.com/customerio/customerio-reactnative/commit/4430b66fc6491a4ba7e1c571eb357a318366af3f))
