# Dominio — Cifrado César

Librería C pura con la lógica del cifrado César. Funciona como *stand-in* didáctico de una librería C de terceros (p. ej. de cifrado): respeta el contrato típico de ese tipo de librerías, de modo que el resto de capas (adaptador C++, TurboModule, integración RN) se construyen igual que con una real.

## El cifrado, en una frase

Desplaza cada letra del texto `key_shift` posiciones en el alfabeto (envolviendo de la `z` a la `a`); el resto de caracteres pasa intacto. Descifrar es desplazar en sentido contrario.

```
"Hola, mundo!" + 5 → "Mtqf, rzsit!"
```

## Contrato (lo que el llamador debe respetar)

- **Buffer reservado por el llamador**: `output_buffer` debe tener capacidad `>= strlen(text) + 1`. La librería no reserva memoria.
- **NUL-termination**: la salida termina en `\0`; la entrada también debe estarlo.
- **Stateless**: no hay contextos, sesiones ni estado global. Cada llamada es independiente y reentrante.
- **Sin custodia de claves**: `key_shift` se pasa por llamada y no se persiste. La gestión de la clave es responsabilidad de la app consumidora.
- **Sin códigos de error**: la API es total — entrada válida ⇒ salida válida.

## Consideraciones para una librería criptográfica real

Lo que aquí es trivial deja de serlo en una librería de cifrado de verdad. Puntos a tener en cuenta al integrar una real:

- **Colisión de símbolos** con `encrypt(3)`/`decrypt(3)` de POSIX → prefijo propio + visibilidad oculta (`-fvisibility=hidden`).
- **Contrato de memoria** explícito: tamaños máximos, quién reserva, qué pasa con NUL embebidos.
- **Estado/sesiones**: si la librería tiene contextos, exponer *handles* opacos en vez de globales.
- **Datos binarios**: `ArrayBuffer` sin copia, nunca base64.
- **Códigos de error estables** mapeados a rechazos de Promise.
- **Custodia de claves** en Keychain/Keystore del consumidor; el módulo nunca persiste.
- **Bloqueo del hilo de JS**: async por defecto, sync como excepción documentada.
- **Certificación (p. ej. FIPS)**: recompilar en el consumidor rompería la certificación → obligaría a distribuir binarios precompilados en vez de fuente.
- **Vectores de prueba conocidos (KAT)** como fuente de verdad para los tests de paridad iOS↔Android.

## Estructura

```
domain/
├── caesar.h            # API pública
├── caesar.c            # implementación
└── tests/
    └── test_caesar.c   # asserts contra casos conocidos
```

## Tests

Compilación directa con cualquier `cc` (sin CMake ni dependencias):

```sh
# Desde caesar-cipher/domain/
cc -I. caesar.c tests/test_caesar.c -o /tmp/test_caesar && /tmp/test_caesar && echo OK
```

Si todos los asserts pasan, imprime `OK`. Si alguno falla, `assert` aborta indicando archivo, línea y función.

> El adaptador C++ ([`../infrastructure/cpp-adapter/`](../infrastructure/cpp-adapter/README.md)) ejecuta tests adicionales con GoogleTest sobre el dominio + el wrapper de buffers. Aquí, los asserts en C son suficientes para validar la lógica pura del dominio.
