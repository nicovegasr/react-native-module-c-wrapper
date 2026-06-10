# scripts — compilar la C a binarios nativos

Convierten `c-library/caesar.c` en los binarios que cada plataforma sabe cargar. Se ejecutan **a mano** cuando cambia la C; las capas superiores solo copian sus outputs.

```bash
bash compile-ios.sh       # → build/ios/Caesar.xcframework
bash compile-android.sh   # → build/android/<abi>/libcaesar.so
```

## `compile-ios.sh` → `Caesar.xcframework`

Compila tres slices y los empaqueta:

```
caesar.c ─┬─ clang arm64-apple-ios            (device)    ─┐
          ├─ clang arm64-apple-ios-simulator  (sim Apple)  ├─ lipo (sim) ─┐
          └─ clang x86_64-apple-ios-simulator (sim Intel) ─┘              ├─ xcodebuild
                                                                          │  -create-xcframework
                                                                          ▼
                                                          Caesar.xcframework
                                                          ├── ios-arm64/
                                                          └── ios-arm64_x86_64-simulator/
```

**La idea clave: plataforma ≠ arquitectura.** Un `arm64` de *device* y un `arm64` de *simulator* son binarios distintos (difieren en el sufijo `-simulator` del target triple). Por eso:

- `lipo` **solo** fusiona arquitecturas dentro de la **misma** plataforma (los dos slices de simulador). Nunca device + simulator: pasa silenciosamente y rompe en runtime.
- Separar device ↔ simulator es trabajo de `xcodebuild -create-xcframework`, no de `lipo`.

Requiere Xcode completo (no solo Command Line Tools): necesita las SDK `iphoneos` e `iphonesimulator`.

## `compile-android.sh` → `libcaesar.so` por ABI

```
caesar.c ─┬─ clang (NDK) aarch64-linux-android34  ─► build/android/arm64-v8a/libcaesar.so
          └─ clang (NDK) x86_64-linux-android34   ─► build/android/x86_64/libcaesar.so
```

Android no necesita contenedor: el runtime elige la `.so` por el nombre del directorio ABI. Decisiones:

- Solo `arm64-v8a` (device) y `x86_64` (emulador). Sin 32-bit (irrelevante en 2026).
- `-fPIC` obligatorio para shared objects; `llvm-strip` reduce tamaño.
- API 34 de compilación, compatible hacia atrás hasta `minSdk 24`.

Requiere NDK r25+ (`ANDROID_NDK_HOME`).

## Quién consume estos binarios

| Output | Lo consume |
|---|---|
| `Caesar.xcframework` | [`swift-implementation/`](../swift-implementation/) (vía su `setup.sh`) |
| `libcaesar.so` por ABI | [`jni-implementation/`](../jni-implementation/) (vía su `setup.sh`) |
