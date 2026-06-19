# react-native-module-c-wrapper

> Dos formas de exponer una **librería C** a **React Native** (New Architecture), implementadas de punta a punta y comparadas.

La librería de ejemplo es un **cifrado César** trivial a propósito (`encrypt` / `decrypt`): el foco está en el **proceso de integración nativa**, no en el algoritmo. Es un *stand-in* de cualquier librería C que necesites llevar a iOS y Android desde JS.

Ambos enfoques exponen **la misma API JS**:

```ts
import { Caesar } from '@nicovegasr/caesar-rn';

Caesar.cipher('Hola, mundo!', 3);   // → 'Krod, pxqgr!'
Caesar.decipher('Krod, pxqgr!', 3); // → 'Hola, mundo!'
```

![Arquitectura: de la librería C a la API JS, por los dos enfoques](assets/architecture.svg)

## Los dos enfoques

- **① Wrappers nativos** — [`01-native-bindings/`](01-native-bindings/README.md): cada plataforma envuelve la C con su propio wrapper nativo (Swift en iOS, Kotlin/JNI en Android) y el TurboModule delega en ellos.
- **② C++ compartido** — [`02-turbo-module-cpp-cross-compiled/`](02-turbo-module-cpp-cross-compiled/README.md): una única implementación C++ (arquitectura hexagonal) sirve a ambas plataformas. Modelo *react-native-reanimated*.

### Comparativa de mantenibilidad

| | **① Wrappers nativos** | **② C++ compartido** |
|---|---|---|
| Implementaciones a mantener | Dos: Swift **y** Kotlin/JNI | Una: C++ |
| Traducción de memoria C↔runtime | A mano en cada lado (C↔Swift y C↔JVM vía JNI) | Una sola vez (C↔JSI) |
| Reutilizable fuera de React Native | **Sí**: el AAR y el pod sirven también a apps nativas Android/iOS | No directamente; pensado para React Native |
| Coste de mantenimiento | Mayor: dos fuentes que sincronizar | Menor: una sola fuente de verdad |
| Encaja mejor con | Equipos móviles con wrappers nativos ya hechos | Equipos centrados en React Native |

En ambos casos lo que se distribuye al final es el **mismo paquete npm** del TurboModule; lo que cambia es cómo está cableado por debajo y qué cuesta mantenerlo.

> **Por qué dos enfoques (y hexagonal).** Lo hice como ejercicio para entender cada pieza por separado: al ir moviendo los directorios se ve cómo se configura **Codegen** para apuntar a cada ruta y cómo se genera la lib final en cada plataforma — en Android vía `react-native.config.js` / Gradle, y en iOS vía el CocoaPod que indica dónde está el `xcframework` (o el código fuente). La arquitectura hexagonal del enfoque ② es precisamente para aislar el dominio C de cada adaptador de infraestructura.

> **Nota sobre el enfoque ②.** Aquí se compila desde **código fuente**, pero no es obligatorio: si solo tienes el **binario + los headers** también funciona, y de hecho es lo más habitual.
> - **iOS**: distintas configuraciones del `Podfile`/podspec apuntando al binario o al fuente.
> - **Android**: con `.so` Gradle se encarga si los pones en `jniLibs/`; con `.a` lo configuras en el `CMakeLists.txt`; con código fuente el propio CMake lo resuelve.

## Estructura

```
react-native-module-c-wrapper/
├── 01-native-bindings/      # ① C → binarios → wrappers Swift/Kotlin → TurboModule
│   ├── c-library/                 librería C + Makefile
│   ├── scripts/                   compilación a .xcframework y .so
│   ├── swift-implementation/      Swift Package + pod
│   ├── jni-implementation/        AAR Kotlin sobre JNI
│   ├── turbo-module-library-gen/  módulo React Native que delega en los wrappers
│   └── react-native-test/         app de ejemplo
│
└── 02-turbo-module-cpp-cross-compiled/      # ② C → adaptador C++ → TurboModule C++ (JSI)
    ├── caesar-cipher/
    │   ├── domain/                librería C (dominio)
    │   └── infrastructure/
    │       ├── cpp-adapter/       adaptador C++ (testeado con GoogleTest)
    │       └── turbo-module/      TurboModule C++ + spec TS
    └── react-native-example-test/ playground React Native + registry local (Verdaccio)
```

Cada carpeta tiene su propio README con el detalle de su capa.

## Otras rutas posibles

Sobre los mismos wrappers nativos caben dos variantes más, no implementadas aquí:

| Ruta | Generador | Cuándo elegirla |
|---|---|---|
| **① Wrappers Swift+Kotlin** | Codegen (oficial) | API estable, equipo móvil sin C++. **Implementada.** |
| **② C++ unificado** | Codegen (oficial) | Lógica CPU-bound, una sola fuente cross-platform. **Implementada.** |
| **Nitro Modules** | Nitrogen (Margelo) | Tipos ricos (records, callbacks, async), solo Swift+Kotlin sin Obj-C++. |
| **Old JSON Arch** | — | Solo si la app consumidora sigue en Old Architecture (deprecated). |
