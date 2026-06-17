# Adaptador C++ sobre el dominio

Capa C++ delgada sobre la librería C de [`../../domain/`](../../domain/README.md). Su única responsabilidad es **adaptar el contrato C inseguro de buffers** a una API moderna en C++ que recibe y devuelve `std::string`.

**Lo que NO hace:** nada relacionado con React Native, JSI, threading o JS. Eso es responsabilidad de [`../turbo-module/`](../turbo-module/README.md). Esta separación permite:

- Tests de host en milisegundos sin SDK móvil.
- Reutilizar el adaptador desde otros bindings (p. ej. Nitro Modules) sin tocarlo.

## API

```cpp
namespace nicovegasr::caesar {
  std::string encrypt(const std::string& text, int shift);
  std::string decrypt(const std::string& text, int shift);
}
```

## Tests (GoogleTest + CTest)

CMake descarga GoogleTest con `FetchContent` en la primera ejecución. Desde la raíz del paquete:

```sh
yarn test:cpp
```

Equivale a:

```sh
cmake -S caesar-cipher/infrastructure/cpp-adapter \
      -B caesar-cipher/infrastructure/cpp-adapter/build \
      -DCAESAR_BUILD_TESTS=ON
cmake --build caesar-cipher/infrastructure/cpp-adapter/build
ctest --test-dir caesar-cipher/infrastructure/cpp-adapter/build --output-on-failure
```

Para limpiar artefactos de build:

```sh
yarn clean
```

Salida esperada (resumida):

```
100% tests passed, 0 tests failed out of 11
```

### Estructura de tests

```
cpp-adapter/
├── CaesarCipher.{h,cpp}
├── CMakeLists.txt          # opción CAESAR_BUILD_TESTS=ON activa el target de tests
└── tests/
    └── CaesarCipherTest.cpp
```

Los tests cubren tanto el dominio como el wrapper de buffers (longitudes grandes, shifts negativos / fuera de rango, caracteres no alfabéticos, etc.).

> Requisito: `cmake` instalado (`brew install cmake` en macOS).
