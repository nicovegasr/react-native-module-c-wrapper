# ① Wrappers nativos por plataforma (JNI + Swift)

> Primer enfoque del monorepo. Cada plataforma envuelve la librería C con su propio wrapper nativo y el TurboModule delega en ellos. El [enfoque ②](../02-turbo-module-cpp-cross-compiled/) usa una única implementación C++. Comparativa en el [README raíz](../README.md).

La integración va de C a JavaScript atravesando **cuatro capas**. La regla mental: **cada capa solo conoce a la inmediatamente inferior**. La capa 4 (React Native) no sabe nada de C ni de `.so`/`.xcframework`; solo habla con los wrappers Swift y Kotlin.

```
caesar.c ──► binarios nativos ──► wrappers nativos ──► módulo React Native
 (Capa 1)      (Capa 2)             (Capa 3)              (Capa 4)
```

| # | Capa | Carpeta | Input → Output | Detalle |
|---|---|---|---|---|
| 1 | Librería C | `c-library/` | fuente → `caesar.c` + `caesar.h` | ↓ abajo |
| 2 | Compilación | [`scripts/`](scripts/README.md) | `caesar.c` → `.xcframework` (iOS), `.so` por ABI (Android) | [README](scripts/README.md) |
| 3a | Wrapper iOS | [`swift-implementation/`](swift-implementation/README.md) | `.xcframework` → Swift Package + pod | [README](swift-implementation/README.md) |
| 3b | Wrapper Android | [`jni-implementation/`](jni-implementation/README.md) | `.so` + `.h` → AAR Kotlin/JNI | [README](jni-implementation/README.md) |
| 4 | Módulo React Native | [`turbo-module-library-gen/`](turbo-module-library-gen/README.md) | wrappers → paquete npm | [README](turbo-module-library-gen/README.md) |

## Capa 1 — La librería C

`c-library/caesar.c` + `caesar.h` son la **interfaz C** y la única fuente de verdad: un cambio aquí afecta a iOS y Android a la vez.

C es un lenguaje compilado que trabaja con **punteros y buffers manuales**, y eso marca a todas las capas de arriba: el caller reserva el buffer de salida (la C no hace `malloc` ni devuelve errores), así que **cada wrapper gestiona su propia memoria** al cruzar a Swift, a la JVM (JNI) o a Obj-C++. Ese es el detalle que hay que tener presente; el algoritmo del cifrado en sí es irrelevante.

## Capa 2 — Compilación a binarios

Dos scripts toman `caesar.c` y producen los binarios que cada plataforma carga: un `Caesar.xcframework` (iOS, con slices device + simulator) y un `libcaesar.so` por ABI (Android). Se ejecutan **a mano** cuando cambia la C. → [`scripts/README.md`](scripts/README.md)

## Capa 3 — Wrappers nativos

Cada plataforma envuelve el binario C en una API idiomática. El paralelismo entre ambos es **deliberado**: el TurboModule delega asumiendo la misma forma de API.

| | iOS — [`swift-implementation/`](swift-implementation/README.md) | Android — [`jni-implementation/`](jni-implementation/README.md) |
|---|---|---|
| Binario C | `Caesar.xcframework` | `libcaesar.so` por ABI |
| Puente a nativo | `import CCaesar` vía `module.modulemap` | bridge JNI (`caesar_jni.c` → `libcaesar-jni.so`) |
| Facade | `enum Caesar` (Swift) | `object Caesar` (Kotlin) |
| API | `cipher(_:shift:Int32) -> String` | `cipher(text, shift: Int): String` |
| Distribución | Swift Package **y** pod (`Caesar.podspec`) | AAR |

> El wrapper iOS se distribuye en dos formas hermanas (Swift Package + pod) sobre el mismo `xcframework`. **El módulo React Native lo consume vía CocoaPods**, no vía SwiftPM, porque la maquinaria nativa de React Native en iOS (Codegen, React-Core) está construida sobre CocoaPods. El Swift Package queda disponible para apps iOS nativas.

## Capa 4 — Módulo React Native

`turbo-module-library-gen/` es **solo un cable**: una spec TypeScript que Codegen convierte en binding JSI, e implementaciones finas que delegan en los wrappers de la capa 3. No toca C: en iOS importa el pod `Caesar`, en Android consume el AAR. → [`turbo-module-library-gen/README.md`](turbo-module-library-gen/README.md)

```typescript
import { Caesar } from '@nicovegasr/caesar-rn';
Caesar.cipher('hello', 3);    // → 'khoor'
Caesar.decipher('khoor', 3);  // → 'hello'
```

## Reproducir desde cero

Requisitos: macOS + Xcode 14+, Android NDK r25+, Node 20+, Yarn 4 (corepack).

```bash
# Capa 2 — compilar la C
bash scripts/compile-ios.sh
bash scripts/compile-android.sh

# Capa 3 — wrappers nativos
(cd swift-implementation && bash setup.sh && bash run-tests.sh)
(cd jni-implementation   && bash setup.sh && bash run-tests.sh)

# Capa 4 — módulo React Native
(cd turbo-module-library-gen && bash setup.sh && corepack enable && yarn && yarn test)

# Smoke test — app de ejemplo
(cd react-native-test && yarn && cd ios && pod install && cd .. && yarn ios)
```

## Cómo lo consume una app externa

```bash
npm install file:../caesar-library/turbo-module-library-gen
```

```ruby
# ios/Podfile — el podspec del módulo declara s.dependency 'Caesar' pero no lo resuelve
pod 'Caesar', :path => '../../caesar-library/swift-implementation'
```

```bash
cd ios && pod install   # Codegen corre aquí
```

Android: nada manual. Autolinking detecta el módulo y su `flatDir` interno expone el AAR.
