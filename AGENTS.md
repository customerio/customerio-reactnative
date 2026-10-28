# Customer.io React Native SDK

React Native wrapper over the native Customer.io Android and iOS SDKs. Runtime behavior lives in this repo; the Expo build-time integration lives in the `customerio-expo-plugin` repo.

## Layout
- `src/`: TypeScript API
- `android/`, `ios/`: native bridge code for the wrapped SDKs
- `example/`: sample app
- `__tests__/`: Jest tests
- `api-extractor-output/`: checked-in public API baseline

## Commands
Run from the repo root.
- Type-check: `npm run typescript`
- Lint: `npm run lint`
- Test: `npm test`
- Build: `npm run prepare`
- Format: `npm run format`

## Conventions
- After changing the exported TypeScript API, run `npm run prepare`, then `npx api-extractor run --local`, and commit the updated `api-extractor-output/customerio-reactnative.api.md`. CI validates with `npx api-extractor run` (`.github/workflows/api-validation.yml`). See `DEVELOPMENT.md`.
- Native SDK versions are pinned in two places: iOS in `package.json` (`cioNativeiOSSdkVersion`, keep the `= ` prefix) and Android in `android/gradle.properties` (`customerio.reactnative.cioSDKVersionAndroid`). The steps are in `.cursor/commands/update-native-sdks.md`.
- Run `npm run lint` before pushing. `lefthook.yml` runs it on pre-push and formats staged `*.tsx` files on pre-commit.
