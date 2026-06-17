#include "CaesarCipher.h"

#include "caesar.h"

namespace nicovegasr::caesar {

namespace {

using DomainOperation = void (*)(const char*, int, char*);

std::string run_with_safe_buffer(const std::string& text,
                                 int shift,
                                 DomainOperation domain_operation) {
  // El dominio escribe strlen(text) + NUL: reservamos +1 y recortamos.
  std::string output(text.size() + 1, '\0');
  domain_operation(text.c_str(), shift, output.data());
  output.resize(text.size());
  return output;
}

}  // namespace

std::string encrypt(const std::string& text, int shift) {
  return run_with_safe_buffer(text, shift, &caesar_encrypt);
}

std::string decrypt(const std::string& text, int shift) {
  return run_with_safe_buffer(text, shift, &caesar_decrypt);
}

}  // namespace nicovegasr::caesar
