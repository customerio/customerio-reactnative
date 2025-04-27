const path = require('path');
const {getConfig} = require('react-native-builder-bob/babel-config');

const pkg = require('./package.json');

const root = __dirname;

module.exports = {
  presets: ['module:@react-native/babel-preset'],
  plugins: [
    [
      'module-resolver',
      {
        root: ['./src'],
        extensions: ['.tsx', '.ts', '.js', '.jsx', '.png', '.json'],
        alias: {
          [pkg.name]: path.join(__dirname, '..'),
          '@assets': './src/assets',
          '@components': './src/components',
          '@constants': './src/constants',
          '@screens': './src/screens',
          '@screens-context': './src/screens/context.ts',
          '@services': './src/services',
          '@colors': './src/colors',
          '@utils': './src/utils',
          '@navigation': './src/navigation',
        },
      },
    ],
  ],
};
