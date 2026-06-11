# Caesar — Swift Package + pod (wrapper iOS)

Wrapper Swift sobre `libcaesar`. Expone una API Swift idiomática que delega en el binario C distribuido como `Caesar.xcframework`. Capa 3.iOS del [enfoque ①](../README.md).

## API

```swift
import Caesar

Caesar.cipher("Hola, mundo!", shift: 3)   // → "Krod, pxqgr!"
Caesar.decipher("Krod, pxqgr!", shift: 3) // → "Hola, mundo!"
```

```swift
public enum Caesar {
    public static func cipher(_ text: String, shift: Int32) -> String
    public static func decipher(_ text: String, shift: Int32) -> String
}
```

Devuelven una `String` nueva y preservan los caracteres no alfabéticos.

## Cómo está montado

```
import Caesar            ← API pública (Sources/Caesar/Caesar.swift)
      │ import CCaesar
      ▼
CCaesar (módulo C)       ← vendor/Caesar.xcframework
      │                     libcaesar.a + caesar.h + module.modulemap
encrypt / decrypt (C)
```

`Package.swift` declara dos targets: un `.binaryTarget` (el xcframework) y el target Swift que lo envuelve.

**La pieza clave — el modulemap.** Sin él Swift no puede importar la C. `setup.sh` lo inyecta en cada slice del xcframework:

```
module CCaesar { header "caesar.h"  export * }
```

Con eso `import CCaesar` ve `encrypt`/`decrypt`. El bridging gestiona el buffer C a mano (reservar, ceder con `withCString`, liberar con `defer`), porque la C no asigna memoria.

## Setup y tests

```bash
bash ../scripts/compile-ios.sh   # produce el xcframework (si no existe)
bash setup.sh                    # copia xcframework + inyecta modulemap
bash run-tests.sh                # 9 XCTest en iOS Simulator
```

## Consumir desde otro proyecto

El paquete es **dual**: dos manifiestos hermanos sobre el mismo `vendor/Caesar.xcframework`.

```swift
// SwiftPM (apps iOS nativas) — Package.swift del consumidor
.package(path: "../caesar-library/swift-implementation")
```

```ruby
# CocoaPods (lo que usa el módulo RN) — Podfile del consumidor
pod 'Caesar', :path => '../../caesar-library/swift-implementation'
```

El módulo RN consume vía CocoaPods: su `CaesarRn.podspec` declara `s.dependency 'Caesar'` y `Caesar.podspec` (hermano de `Package.swift`) lo resuelve.

## Estructura

```
swift-implementation/
├── Package.swift            manifiesto SwiftPM
├── Caesar.podspec           manifiesto CocoaPods (hermano)
├── Sources/Caesar/Caesar.swift
├── Tests/CaesarTests/       9 XCTest
├── vendor/Caesar.xcframework  (regenerable, gitignored)
├── setup.sh                 copia xcframework + inyecta modulemap
└── run-tests.sh
```

Plataformas: iOS 16+ (device arm64, simulator arm64/x86_64). macOS/tvOS/watchOS requerirían regenerar el xcframework con más slices.
