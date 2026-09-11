module.exports = {
  testEnvironment: 'node',
  testMatch: ['<rootDir>/__tests__/**/*.test.ts'],
  globals: {
    // React Native defines `__DEV__` at runtime; the bare node environment does not, so any test
    // reaching the `assert.*` parameter validation in src/utils/param-validation.ts would throw a
    // ReferenceError instead of exercising the validation. Matches React Native's own jest preset.
    __DEV__: true,
  },
};
