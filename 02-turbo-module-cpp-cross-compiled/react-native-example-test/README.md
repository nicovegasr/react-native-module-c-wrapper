# react-native-example-test

Playground de RN para validar end-to-end el TurboModule de `@nicovegasr/caesar-rn`.

```
react-native-example-test/
└── CaesarExample/            # app RN
    ├── App.tsx               # playground: input + encrypt/decrypt[Sync] + payloads
    ├── .yarnrc.yml           # apunta @nicovegasr al Verdaccio local
    └── maestro/parity.yml    # flow E2E
```

## Qué muestra la app

Pantalla con:
- `TextInput` multilínea para pegar el texto.
- Selector de `shift`.
- Generadores de payload de **10k / 100k / 1M** caracteres para probar carga.
- Cuatro botones: `encrypt`, `decrypt`, `encryptSync`, `decryptSync`. Los `*Sync` están marcados en rojo porque bloquean el hilo JS.
- Cabecera con un **indicador de congelación**: un spinner animado (driver nativo, no se congela) + un contador `setInterval` (driven por JS, **se congela** durante un `*Sync` con payload grande).
- Caja de resultado con tiempo (ms), longitudes de entrada/salida y preview de 200 caracteres.

Útil para comparar visualmente latencia async vs sync y ver el bloqueo del hilo JS en directo.

## Arrancar emuladores y la app

### Prerrequisitos

| Herramienta | Cómo |
|---|---|
| Node 20+ | `nvm install 20` |
| Yarn (Berry) | viene en el repo (`.yarn/releases`) |
| Docker | para Verdaccio |
| **iOS**: Xcode + CocoaPods | `gem install cocoapods` o `bundle install` |
| **iOS**: Simulator | `xcrun simctl list devices` para confirmar que tienes uno instalado |
| **Android**: Android Studio | con SDK Platform 36, NDK 27.1.12297006, CMake 3.22.1 |
| **Android**: AVD | crea uno desde Android Studio → *Device Manager* |
| **Android**: `ANDROID_HOME` exportado | suele ser `~/Library/Android/sdk` en macOS |

Comprueba con `npx react-native doctor` desde `CaesarExample/`.

### Levantar un simulador iOS

```sh
# Lista los devices disponibles
xcrun simctl list devices available

# Arranca uno (sustituye el UDID o usa el nombre)
xcrun simctl boot "iPhone 17 Pro"
open -a Simulator         # abre la ventana
```

`yarn ios` también arranca un simulador por defecto si no hay ninguno; usar el comando manual sólo si quieres elegir el modelo.

### Levantar un emulador Android

```sh
# Lista los AVDs creados en Android Studio
~/Library/Android/sdk/emulator/emulator -list-avds

# Arranca uno (sustituye por el nombre)
~/Library/Android/sdk/emulator/emulator -avd Pixel_8 &

# Comprueba que ADB lo ve
adb devices    # debe aparecer "emulator-5554  device"
```

Si tras `yarn android` la app no resuelve `localhost:8081` en el emulador:

```sh
adb reverse tcp:8081 tcp:8081
```

### Lanzar la app

En una terminal aparte, Metro:

```sh
cd react-native-example-test/CaesarExample
yarn start                # con --reset-cache si has cambiado deps nativas
```

En otra terminal, build + install:

```sh
cd react-native-example-test/CaesarExample
yarn ios                  # usa el simulador iOS arrancado
# o
yarn android              # usa el emulador Android arrancado
```

iOS la primera vez (o tras tocar deps nativas):

```sh
cd ios && bundle install && bundle exec pod install && cd ..
```

### Diagnóstico rápido cuando algo no tira

```sh
# Logs de runtime Android (Invariant Violation, crashes nativos, etc.)
adb logcat -d ReactNative:V ReactNativeJS:V AndroidRuntime:E '*:S' | tail -50

# Logs de runtime iOS
xcrun simctl spawn booted log stream --predicate 'process == "CaesarExample"' --level debug

# Si el build Android peta en CMake con "generated/jni does not exist",
# limpia todo y reconstruye:
cd android && ./gradlew clean && cd ..
rm -rf android/app/.cxx android/app/build node_modules/@nicovegasr/caesar-rn/caesar-cipher/infrastructure/turbo-module/android/build
yarn android
```

### (Opcional) E2E con Maestro

```sh
maestro test maestro/parity.yml
```

---

## Bonus: publicar la librería en un Verdaccio local

Para que la app consuma cambios de `@nicovegasr/caesar-rn` sin pasar por npmjs.org, usamos [Verdaccio](https://verdaccio.org) en `localhost:4873`. Está orquestado con Docker desde la raíz del módulo (`02-turbo-module-cpp-cross-compiled/docker-compose.yml`).

### Setup inicial

```sh
cd 02-turbo-module-cpp-cross-compiled

# 1. Arranca Verdaccio (Docker)
yarn registry:start                 # alias de: docker compose up -d
# para pararlo: yarn registry:stop

# 2. Sanity check
curl -s http://localhost:4873/-/ping  # → "{}"

# 3. Login (sólo la primera vez por máquina)
npm adduser --registry http://localhost:4873
# acepta cualquier user/pass/email; Verdaccio en modo dev los acepta todos
```

### Ciclo "tocar libreria → probar en la app"

```sh
cd 02-turbo-module-cpp-cross-compiled

# 1. Compila los JS/TS targets que se incluyen en el paquete
yarn prepare                        # alias de: bob build

# 2. Sube versión (Verdaccio no deja sobrescribir una versión publicada)
npm version patch --no-git-tag-version   # 0.1.4 → 0.1.5

# 3. Publica al registry local
npm publish --registry http://localhost:4873

# 4. Actualiza la app a la nueva versión
cd react-native-example-test/CaesarExample
yarn add @nicovegasr/caesar-rn@latest       # o pin exacto: @0.1.5

# 5. Si hay cambios C/C++/Kotlin/iOS nativos, limpia caches antes del build
rm -rf android/app/.cxx android/app/build node_modules/@nicovegasr/caesar-rn/caesar-cipher/infrastructure/turbo-module/android/build
cd ios && bundle exec pod install && cd ..   # iOS

# 6. Rebuild
yarn android      # y/o
yarn ios
```

> El `.yarnrc.yml` de `CaesarExample/` ya redirige el scope `@nicovegasr` a `http://localhost:4873`, así que `yarn add` lo resuelve automáticamente sin tocar `--registry`.

### Comandos útiles del paquete

```sh
# Desde 02-turbo-module-cpp-cross-compiled/
yarn typecheck                      # tsc
yarn test                           # jest (specs JS)
yarn test:cpp                       # CMake + ctest del cpp-adapter
yarn clean                          # borra lib/ y build/ del cpp-adapter
```

### Inspeccionar el paquete que se publicaría

```sh
cd 02-turbo-module-cpp-cross-compiled
npm pack --dry-run                  # lista los archivos sin generar tarball
npm pack                            # genera nicovegasr-caesar-rn-X.Y.Z.tgz local
tar -tzf nicovegasr-caesar-rn-*.tgz | head -40
```

### Verificar qué versión consume la app

```sh
cd react-native-example-test/CaesarExample
cat node_modules/@nicovegasr/caesar-rn/package.json | grep '"version"'
```

### "Empezar de cero" (Verdaccio limpio)

```sh
cd 02-turbo-module-cpp-cross-compiled
yarn registry:stop
docker volume rm 02-turbo-module-cpp-cross-compiled_verdaccio-storage 2>/dev/null
yarn registry:start
# y vuelve a publicar desde 0.1.0
```

---

## Resultado esperado (texto corto, shift 5)

```
plaintext: Hola, mundo!
encrypted: Mtqf, rzsit!
decrypted: Hola, mundo!
```

Para pruebas de carga sube a 100k–1M caracteres con los botones de la app: con `encrypt`/`decrypt` (async) el contador de cabecera sigue subiendo durante la operación; con `encryptSync`/`decryptSync` el contador se queda congelado hasta que termina.

## Notas

- **Bundle IDs**: Android usa `com.caesarexample` e iOS `org.reactjs.native.example.CaesarExample`. `maestro/parity.yml` apunta al de Android.
- **Sin `__tests__` en la app**: el snapshot test del scaffold se quitó porque importa `@nicovegasr/caesar-rn`, que no existe hasta el primer `yarn add`. Para tests JS aquí, mockea el TurboModule.
