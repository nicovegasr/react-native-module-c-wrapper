# @nicovegasr/caesar-rn — módulo React Native

TurboModule que conecta JS con los wrappers nativos: en iOS delega en el [Swift Package/pod](../swift-implementation/README.md), en Android en el [AAR Kotlin/JNI](../jni-implementation/README.md). **No reimplementa el bridging a C — es solo un cable.** Capa 4 del [enfoque ①](../README.md).

## API

```typescript
import { Caesar } from '@nicovegasr/caesar-rn';
Caesar.cipher('Hola, mundo!', 3);   // → 'Krod, pxqgr!'
```

Síncrono (JSI, sin serialización JSON), sin estado, thread-safe — garantías heredadas de los wrappers de capa 3.

## Cómo se cablea

```
src/NativeCaesarRn.ts   spec TurboModule (contrato que dispara Codegen)
src/index.tsx           fachada pública Caesar
        │ Codegen genera el binding JSI
   ┌────┴─────────────────────┐
   ▼                          ▼
ios/CaesarRn.mm (Obj-C++)   android/.../CaesarRnModule.kt
   │ via shim @objc            │ directo
CaesarRnSwiftBridge.swift    com.nicovegasr.caesar.Caesar
   │                          (del AAR)
Caesar (pod, capa 3.iOS)
```

El módulo tiene tres sub-capas: **JS** (spec + fachada), **Codegen** (genera el binding nativo, sin tocar nada a mano) y **nativa** (delega en los wrappers).

### La spec y Codegen

```typescript
export interface Spec extends TurboModule {
  cipher(text: string, shift: number): string;
  decipher(text: string, shift: number): string;
}
export default TurboModuleRegistry.getEnforcing<Spec>('CaesarRn');
```

- El archivo debe empezar por `Native…` y el nombre del módulo (`'CaesarRn'`) debe coincidir con `+moduleName` (iOS) y `NAME` (Android).
- `codegenConfig` en `package.json` apunta a `src/`. Codegen genera `RNCaesarRnSpec` (iOS) y `NativeCaesarRnSpec.java` (Android) en cada build. **Nunca se editan a mano.**
- `number` de JS → `double` en nativo; se castea a `Int32`/`Int` para llamar a los wrappers.

### iOS — por qué un shim Swift

El protocolo TurboModule es **Obj-C++**, y `Caesar` es un `enum` Swift que Obj-C no puede llamar directo (no es `@objc`). Solución: un shim `@objc public class : NSObject` (`CaesarRnSwiftBridge.swift`) que Xcode expone vía `CaesarRn-Swift.h`. `CaesarRn.mm` lo invoca.

El podspec declara `s.dependency "Caesar"` y **no vendora el xcframework** (el pod `Caesar` ya lo trae; duplicarlo da "duplicate symbol _encrypt").

### Android — directo

Kotlin extiende `NativeCaesarRnSpec` (generada por Codegen) e invoca `com.nicovegasr.caesar.Caesar` del AAR. Sin shim. El AAR se resuelve con `flatDir { dirs "libs" }`; lo rellena `setup.sh` (`./gradlew assembleRelease` en `jni-implementation/` + copia).

> Lo siguiente vive en el AAR, **no aquí**: `libcaesar(-jni).so`, `caesar_jni.c`, `System.loadLibrary`, `external fun`. Si aparece en este módulo, se duplicó por error.

## Workflow

```bash
# Primer build: compilar C + setup de wrappers (ver README de capa 2 y 3), luego:
bash setup.sh        # build del AAR + copia a android/libs/
corepack enable && yarn
yarn typecheck && yarn test   # Jest del pegamento JS (mockea el nativo)
```

Smoke test end-to-end real: app en [`../react-native-test/`](../react-native-test/).

## Cuando cambies la API

La firma se propaga en orden: `caesar.h`/`.c` → `Caesar.swift` → `Caesar.kt` (+`caesar_jni.c` si cambia la C) → `NativeCaesarRn.ts` → `CaesarRn.mm`+`CaesarRnSwiftBridge.swift` → `CaesarRnModule.kt` → `index.tsx` → tests. Saltarse un paso suele romper el linker (iOS) o dar `NoSuchMethodError` (Android).

## Problemas comunes

| Síntoma | Causa |
|---|---|
| `pod install` falla con "Caesar not found" | Falta `pod 'Caesar', :path => ...` en el `Podfile` del consumidor |
| `TurboModule CaesarRn not found` | Autolinking no detectó el paquete, o `newArchEnabled` apagado |
| `Caesar.cipher is not a function` | Spec sin rebuild: `yarn prepare` + Metro `--reset-cache` |
| Duplicate symbol `_encrypt` (iOS) | Vendoraste el xcframework dos veces; solo en el pod `Caesar` |
| `UnsatisfiedLinkError: libcaesar.so` | Falta el AAR en `android/libs/`: corre `bash setup.sh` |
