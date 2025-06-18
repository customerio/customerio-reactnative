// Required to keep CommonJS format for React Native CLI compatibility
module.exports = {
  dependency: {
    platforms: {
      android: {
        // Path to the generated code for Android
        // This is where the codegen-sync script will copy codegen generated files
        cmakeListsPath: 'generated/jni/CMakeLists.txt',
      },
    },
  },
};
