require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "Caesar"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = "https://github.com/nicovegasr/react-native-module-c-wrapper"
  s.license      = package["license"]
  s.authors      = package["author"]
  s.platforms    = { :ios => "15.1" }
  s.source       = { :git => "https://github.com/nicovegasr/react-native-module-c-wrapper.git", :tag => "v#{s.version}" }

  s.source_files = "caesar-cipher/domain/**/*.{h,c}",
                   "caesar-cipher/infrastructure/cpp-adapter/**/*.{h,hpp,cpp}",
                   "caesar-cipher/infrastructure/turbo-module/cpp/**/*.{h,hpp,cpp}",
                   "caesar-cipher/infrastructure/turbo-module/ios/**/*.{h,m,mm}"
  s.exclude_files = "caesar-cipher/infrastructure/cpp-adapter/tests/**/*",
                    "caesar-cipher/domain/test_*.c"

  s.pod_target_xcconfig = {
    "CLANG_CXX_LANGUAGE_STANDARD" => "c++20",
    "HEADER_SEARCH_PATHS" => [
      "\"$(PODS_TARGET_SRCROOT)/caesar-cipher/domain\"",
      "\"$(PODS_TARGET_SRCROOT)/caesar-cipher/infrastructure/cpp-adapter\"",
      "\"$(PODS_TARGET_SRCROOT)/caesar-cipher/infrastructure/turbo-module/cpp\""
    ].join(" "),
    # Símbolos ocultos por defecto: evita colisiones (p.ej. encrypt(3) POSIX)
    # y reduce superficie pública del binario.
    "GCC_SYMBOLS_PRIVATE_EXTERN" => "YES"
  }

  # Añade las dependencias de React Native (React-Core, ReactCommon, codegen…)
  # según la versión de RN de la app consumidora.
  install_modules_dependencies(s)
end
