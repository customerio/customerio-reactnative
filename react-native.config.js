// Required to keep CommonJS format for React Native CLI compatibility
module.exports = {
  dependency: {
    platforms: {
      android: {
        componentDescriptors: ['InlineInAppMessageViewComponentDescriptor'],
        cmakeListsPath: 'generated/jni/CMakeLists.txt',
      },
    },
  },
};
