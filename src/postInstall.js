/*
  This code block attempts to set expoVersion in package.json.
  If it fails, the assumption is that Expo plugin is not installed,
  therefore we are running on bare React Native project.
  If it succeeds, we use Expo as the user agent instead of React Native.
*/
try {
  const ph = require('customerio-expo-plugin/postinstall');
  ph.runPostInstall();
} catch {}
