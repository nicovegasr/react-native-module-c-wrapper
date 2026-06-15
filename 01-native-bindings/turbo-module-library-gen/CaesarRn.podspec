require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "CaesarRn"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => min_ios_version_supported }
  s.source       = { :git => "https://github.com/nicovegasr/react-native-module-c-wrapper.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift,cpp}"
  s.private_header_files = "ios/**/*.h"

  # Wrapper Swift hermano. El Podfile del consumer debe declararlo por path:
  #   pod 'Caesar', :path => '../../../swift-implementation'
  # No se vendora el xcframework aquí: el pod 'Caesar' ya lo trae.
  s.dependency "Caesar"

  install_modules_dependencies(s)
end
