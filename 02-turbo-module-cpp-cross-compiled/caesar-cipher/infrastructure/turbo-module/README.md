# Adaptador TurboModule (React Native)

Integración del adaptador C++ ([`../cpp-adapter/`](../cpp-adapter/README.md)) en React Native como **TurboModule C++ puro** sobre JSI. Único punto de contacto entre RN y el resto del módulo.

## Estructura

```
turbo-module/
├── js/                           # consumido por bob (build de NPM) y por codegen
│   ├── NativeCaesar.ts           # SPEC = superficie pública (cambio incompatible ⇒ major)
│   ├── index.tsx                 # fachada que las apps importan
│   └── __tests__/index.test.tsx  # tests Jest
├── cpp/CaesarTurboModule.{h,cpp} # impl JSI ⇄ cpp-adapter (threading, tipos)
├── ios/CaesarModuleProvider.{h,mm}  # shim de registro (autolinking iOS)
└── android/CMakeLists.txt        # target que enlaza domain + cpp-adapter + cpp/
```

> **Convención de agrupación**: spec TS, fachada JS, C++/iOS/Android viven juntos porque son **partes del mismo adaptador**. Para añadir Nitro Modules en el futuro, crear `infrastructure/nitro-module/` como hermano — no son ejes ortogonales.

## API pública (fachada)

```ts
import { encrypt, decrypt, encryptSync, decryptSync } from '@nicovegasr/caesar-rn';

await encrypt(text, shift);      // async por defecto; no bloquea el hilo de JS
encryptSync(text, shift);        // bloquea: solo para textos pequeños
```

## Tests

### Fachada JS (Jest)

El módulo nativo se mockea; verificamos que la fachada delega sin transformar argumentos ni resultados (la lógica real se testea en `cpp-adapter` y E2E).

```sh
yarn test
```

Salida esperada: `Tests: 4 passed, 4 total`.

### Tests del adaptador C++ subyacente

Los tests de cifrado/descifrado en C++ viven en [`../cpp-adapter/tests/`](../cpp-adapter/README.md) — corren con GoogleTest en host vía `yarn test:cpp`. **No duplicamos esa cobertura aquí**.

### Pendiente: E2E

- **E2E (Maestro)** sobre [`react-native-example-test/`](../../../react-native-example-test/README.md) ejecutando los mismos casos conocidos en iOS y Android para validar paridad.
- **`test-vectors.json`** compartido entre `cpp-adapter` y E2E.

## Tipos generados (codegen)

`codegenConfig` en `package.json` apunta a `caesar-cipher/infrastructure/turbo-module/js`. En el build de la app consumidora, codegen genera de `NativeCaesar.ts`:

- iOS: `CaesarSpecJSI.h` (vía CocoaPods, `React-Codegen/`)
- Android: `CaesarSpecJSI.h` en `android/generated/jni/`

El TurboModule C++ hereda de `NativeCaesarCxxSpec<CaesarTurboModule>`, tipo generado a partir de la spec.

## Registro nativo (autolinking)

- **iOS**: `codegenConfig.ios.modulesProvider` (`package.json`) → `CaesarModuleProvider`. La app no toca `AppDelegate`.
- **Android**: `react-native.config.js` → `cmakeListsPath` + `cxxModuleCMakeListsPath` apuntan a `turbo-module/android/`. La CLI mete el target `react-native-caesar` en `appmodules` y registra `CaesarTurboModule` por `cxxModuleHeaderName`.
