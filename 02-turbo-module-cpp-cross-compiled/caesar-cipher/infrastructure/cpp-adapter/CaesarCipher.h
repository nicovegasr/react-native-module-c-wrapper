#pragma once

#include <string>

// Sin headers de JSI ni de React Native: permite testear en host
// y reutilizar este adaptador desde otros bindings.
namespace nicovegasr::caesar {

std::string encrypt(const std::string& text, int shift);
std::string decrypt(const std::string& text, int shift);

}  // namespace nicovegasr::caesar
