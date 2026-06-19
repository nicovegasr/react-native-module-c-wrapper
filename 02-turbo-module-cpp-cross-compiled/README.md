# @nicovegasr/caesar-rn

TurboModule de React Native (New Architecture) con implementación **C++ compartida** entre iOS y Android. El cifrado César es un *stand-in* didáctico de cualquier librería C que quieras exponer a RN. El paquete se distribuye **como código fuente en NPM** (modelo react-native-reanimated): el C++ lo compila la app consumidora. No publicamos AAR, xcframework ni binarios.

> Segundo enfoque del monorepo. El primero ([`../01-native-bindings/`](../01-native-bindings/)) envuelve la librería con wrappers nativos por plataforma; aquí una **única** implementación C++ sirve a ambas.

## Estructura (hexagonal)

```
caesar-cipher/
├── domain/                  # Librería C: lógica del cifrado, sin dependencias
└── infrastructure/
    ├── cpp-adapter/         # Adaptador C++ sobre domain/ (sin headers de RN)
    └── turbo-module/        # Adaptador RN agrupado por convención
        ├── js/              # Spec TS + fachada
        ├── cpp/             # TurboModule (JSI)
        ├── ios/             # ModuleProvider
        └── android/         # CMakeLists para autolinking
```

Cada `infrastructure/<adaptador>/` es **una integración independiente** del dominio. Añadir Nitro Modules en el futuro = carpeta hermana, sin tocar `cpp-adapter` ni `turbo-module`.

Detalle por capa:

- [`caesar-cipher/domain/`](caesar-cipher/domain/README.md)
- [`caesar-cipher/infrastructure/cpp-adapter/`](caesar-cipher/infrastructure/cpp-adapter/README.md)
- [`caesar-cipher/infrastructure/turbo-module/`](caesar-cipher/infrastructure/turbo-module/README.md)

## Setup

```sh
corepack enable                 # activa yarn 4 (campo packageManager)
yarn                            # instala deps
brew install cmake              # requerido por test:cpp
```

## Tests

Tres niveles. Cada uno se ejecuta de forma independiente.

### 1. Dominio C (`domain/`)

Asserts puros en C; compila con cualquier `cc`, sin toolchain extra.

```sh
cd caesar-cipher/domain
cc -I. caesar.c tests/test_caesar.c -o /tmp/test_caesar && /tmp/test_caesar && echo OK
```

Salida esperada: `OK`. Si algún assert falla, aborta con fichero/línea/función.

### 2. Adaptador C++ (`cpp-adapter/`) — GoogleTest en host

CMake + GoogleTest. Corre en Linux/macOS sin SDK móvil; pensado para TDD del adaptador en milisegundos.

```sh
yarn test:cpp
```

Internamente:
```sh
cmake -S caesar-cipher/infrastructure/cpp-adapter \
      -B caesar-cipher/infrastructure/cpp-adapter/build \
      -DCAESAR_BUILD_TESTS=ON
cmake --build caesar-cipher/infrastructure/cpp-adapter/build
ctest --test-dir caesar-cipher/infrastructure/cpp-adapter/build --output-on-failure
```

GoogleTest se descarga con `FetchContent` en la primera ejecución. Para limpiar la build:

```sh
yarn clean
```

### 3. Fachada JS (`turbo-module/js/`) — Jest

El módulo nativo se mockea; verificamos que `encrypt/decrypt[Sync]` delegan sin transformar argumentos ni resultados.

```sh
yarn test
```

### 4. Typecheck

```sh
yarn typecheck
```

### Pendiente: E2E

- **E2E (Maestro)** sobre `react-native-example-test/` para validar paridad iOS↔Android.
- **`test-vectors.json`** compartido entre `cpp-adapter` y E2E como fuente única de casos conocidos.

## Build del paquete

```sh
yarn prepare                    # bob → lib/ (JS ESM + .d.ts)
```

`lib/` es lo que se publica en NPM junto con `caesar-cipher/` (fuentes C/C++/iOS/Android).

## Registry local (Verdaccio)

```sh
yarn registry:start             # http://localhost:4873
npm publish --registry http://localhost:4873
```

## Requisitos

- **iOS**: arm64 (device + sim) y x86_64 (sim), Xcode 16+, mín. iOS 15.1.
- **Android**: API 34+, arm64-v8a + x86_64, NDK r27+ (alineación de página 16 KB).
- **React Native**: ≥ 0.80 con Nueva Arquitectura activada.

## Licencia

MIT
