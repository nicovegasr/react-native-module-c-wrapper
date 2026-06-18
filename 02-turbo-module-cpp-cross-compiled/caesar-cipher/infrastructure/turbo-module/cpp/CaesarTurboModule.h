#pragma once

#include <memory>
#include <string>

#if __has_include(<React-Codegen/CaesarSpecJSI.h>)
#include <React-Codegen/CaesarSpecJSI.h>  // iOS (CocoaPods)
#else
#include <CaesarSpecJSI.h>  // Android (codegen en android/generated/jni)
#endif

namespace facebook::react {

// El nombre de clase y de header deben coincidir con `cxxModuleHeaderName`
// de react-native.config.js (Android) y con el ModuleProvider de ios/.
class CaesarTurboModule : public NativeCaesarCxxSpec<CaesarTurboModule> {
 public:
  explicit CaesarTurboModule(std::shared_ptr<CallInvoker> jsInvoker);

  AsyncPromise<std::string> encrypt(jsi::Runtime& rt, std::string text, double shift);
  AsyncPromise<std::string> decrypt(jsi::Runtime& rt, std::string text, double shift);

  std::string encryptSync(jsi::Runtime& rt, std::string text, double shift);
  std::string decryptSync(jsi::Runtime& rt, std::string text, double shift);
};

}  // namespace facebook::react
