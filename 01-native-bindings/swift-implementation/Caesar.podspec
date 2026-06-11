Pod::Spec.new do |s|
  s.name         = "Caesar"
  s.version      = "0.1.0"
  s.summary      = "Swift wrapper for libcaesar (cipher / decipher)."
  s.description  = <<-DESC
    Caesar cipher implementado en C (libcaesar) y expuesto con API Swift
    (`Caesar.cipher` / `Caesar.decipher`). Mismo binario que el Swift Package
    hermano: ambos vendoran vendor/Caesar.xcframework, que expone el módulo
    Clang `CCaesar` vía module.modulemap.
  DESC
  s.homepage     = "https://github.com/nicovegasr/react-native-module-c-wrapper"
  s.license      = { :type => "MIT" }
  s.authors      = { "Nicolas Vegas Rodriguez" => "nicovegasr@gmail.com" }

  s.platform     = :ios, "16.0"
  s.swift_version = "5.9"

  # Solo consumible por path local desde un Podfile (no publicado a trunk).
  s.source       = { :git => "https://github.com/nicovegasr/react-native-module-c-wrapper.git", :tag => s.version.to_s }

  s.source_files = "Sources/Caesar/**/*.swift"
  s.vendored_frameworks = "vendor/Caesar.xcframework"
end
