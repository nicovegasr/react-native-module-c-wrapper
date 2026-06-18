/**
 * Configuración de autolinking para módulos C++ puros (sin JNI manual).
 * Docs: https://github.com/react-native-community/cli/blob/main/docs/autolinking.md#pure-c-libraries
 *
 * En Android, el build de la app:
 *  1. incluye <sourceDir>/generated/jni/CMakeLists.txt (codegen → react_codegen_CaesarSpec)
 *  2. añade <sourceDir>/CMakeLists.txt y enlaza el target indicado en appmodules
 *  3. registra la clase de `cxxModuleHeaderName` en el TurboModule provider generado
 *
 * `sourceDir` apunta al adaptador TurboModule dentro de la estructura hexagonal.
 */
module.exports = {
  dependency: {
    platforms: {
      android: {
        sourceDir: 'caesar-cipher/infrastructure/turbo-module/android',
        cmakeListsPath: 'build/generated/source/codegen/jni/CMakeLists.txt',
        cxxModuleCMakeListsModuleName: 'react-native-caesar',
        cxxModuleCMakeListsPath: 'CMakeLists.txt',
        cxxModuleHeaderName: 'CaesarTurboModule',
      },
    },
  },
};
