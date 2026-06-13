# Caesar — AAR Kotlin/JNI (wrapper Android)

Wrapper Android sobre `libcaesar`. Expone una API Kotlin idiomática que delega en el `.so` C a través de un bridge JNI, empaquetado como AAR. Capa 3.Android del [enfoque ①](../README.md).

## API

```kotlin
import com.nicovegasr.caesar.Caesar

Caesar.cipher("Hola, mundo!", 3)   // → "Krod, pxqgr!"
Caesar.decipher("Krod, pxqgr!", 3) // → "Hola, mundo!"
```

```kotlin
object Caesar {
    fun cipher(text: String, shift: Int): String
    fun decipher(text: String, shift: Int): String
}
```

Funciones puras, thread-safe, preservan los caracteres no alfabéticos.

## Cómo está montado

```
Caesar (Kotlin facade)        ← src/main/kotlin/.../Caesar.kt
      │ external fun (JNI)
      ▼
JNI bridge (C)                ← src/main/cpp/caesar_jni.c → libcaesar-jni.so
      │ encrypt / decrypt        convierte jstring ↔ char*, reserva buffer
      ▼
libcaesar.so (C)              ← src/main/jniLibs/<abi>/  (prebuilt por scripts/)
```

El AAR lleva **dos `.so` por ABI**: `libcaesar.so` (la C, intacta) y `libcaesar-jni.so` (el bridge, compilado por AGP). `System.loadLibrary("caesar-jni")` carga el segundo y, vía `DT_NEEDED`, arrastra el primero.

**La pieza clave — el bridge JNI.** La JVM y la C tienen modelos de memoria distintos (UTF-16 vs UTF-8, GC vs `malloc`). `caesar_jni.c` traduce entre ambos con un único path de cleanup para no fugar memoria:

```c
const char *src = (*env)->GetStringUTFChars(env, input, NULL);
char *out = malloc(strlen(src) + 1);
encrypt(src, (int)shift, out);
(*env)->ReleaseStringUTFChars(env, input, src);
jstring result = (*env)->NewStringUTF(env, out);
free(out);
return result;
```

El `.so` C **no se recompila desde Gradle**: lo produce `scripts/compile-android.sh` con el NDK, y CMake lo declara `IMPORTED`.

## Setup y tests

```bash
bash ../scripts/compile-android.sh   # produce los .so por ABI (si no existen)
bash setup.sh                        # copia .so + caesar.h
bash run-tests.sh                    # 9 tests instrumentados en emulador
./gradlew assembleRelease            # produce el AAR
```

Los tests son **instrumentados** (no JVM puros) porque JNI requiere cargar un `.so` ELF Android real; Robolectric no lo resuelve de forma fiable.

## Consumir desde otro proyecto

```kotlin
// Composite build (desarrollo local) — settings.gradle.kts del consumidor
includeBuild("../caesar-library/jni-implementation")
// build.gradle.kts: implementation("com.nicovegasr:caesar-android")
```

```kotlin
// AAR plano (drop-in)
implementation(files("libs/caesar-android-release.aar"))
```

El módulo RN lo consume como AAR plano vía `flatDir { dirs "libs" }`.

## Estructura

```
jni-implementation/
├── build.gradle.kts
├── setup.sh                 copia .so + caesar.h desde el monorepo
├── run-tests.sh
└── src/main/
    ├── kotlin/.../Caesar.kt  facade Kotlin
    ├── cpp/                  caesar_jni.c + CMakeLists.txt (bridge)
    └── jniLibs/<abi>/libcaesar.so   (prebuilt, gitignored)
```

ABIs: `arm64-v8a` (device) + `x86_64` (emulador). `minSdk 24`, `compileSdk 34`, NDK r25+.
