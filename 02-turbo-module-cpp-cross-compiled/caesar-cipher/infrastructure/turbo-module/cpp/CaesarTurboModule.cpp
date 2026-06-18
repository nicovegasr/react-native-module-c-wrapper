#include "CaesarTurboModule.h"

#include <thread>
#include <utility>

#include "CaesarCipher.h"

namespace facebook::react {

namespace {

// JSI representa los `number` de JS como `double`; el dominio espera `int`.
int narrow_to_shift(double js_number) {
  return static_cast<int>(js_number);
}

}  // namespace

CaesarTurboModule::CaesarTurboModule(std::shared_ptr<CallInvoker> jsInvoker)
    : NativeCaesarCxxSpec(std::move(jsInvoker)) {}

AsyncPromise<std::string> CaesarTurboModule::encrypt(jsi::Runtime& rt,
                                                     std::string text,
                                                     double shift) {
  auto promise = AsyncPromise<std::string>(rt, jsInvoker_);
  // Hilo por llamada: placeholder. Sustituir por un pool si el dominio real
  // hace trabajo costoso o muy frecuente.
  std::thread([promise, text = std::move(text), shift]() mutable {
    promise.resolve(nicovegasr::caesar::encrypt(text, narrow_to_shift(shift)));
  }).detach();
  return promise;
}

AsyncPromise<std::string> CaesarTurboModule::decrypt(jsi::Runtime& rt,
                                                     std::string text,
                                                     double shift) {
  auto promise = AsyncPromise<std::string>(rt, jsInvoker_);
  std::thread([promise, text = std::move(text), shift]() mutable {
    promise.resolve(nicovegasr::caesar::decrypt(text, narrow_to_shift(shift)));
  }).detach();
  return promise;
}

std::string CaesarTurboModule::encryptSync(jsi::Runtime& /*rt*/,
                                           std::string text,
                                           double shift) {
  return nicovegasr::caesar::encrypt(text, narrow_to_shift(shift));
}

std::string CaesarTurboModule::decryptSync(jsi::Runtime& /*rt*/,
                                           std::string text,
                                           double shift) {
  return nicovegasr::caesar::decrypt(text, narrow_to_shift(shift));
}

}  // namespace facebook::react
