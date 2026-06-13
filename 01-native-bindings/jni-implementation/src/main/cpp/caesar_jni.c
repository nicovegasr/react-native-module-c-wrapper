/*
 * caesar_jni.c — Puente JNI entre Caesar.kt (JVM) y libcaesar.so (C).
 *
 * Este fichero NO implementa el cifrado César. Lo único que hace es
 * ADAPTAR tipos y memoria entre dos mundos antes de delegar en libcaesar:
 *
 *   ┌─────────────────────────────┬─────────────────────────────────────┐
 *   │ Mundo JVM (Kotlin)          │ Mundo C (libcaesar)                 │
 *   ├─────────────────────────────┼─────────────────────────────────────┤
 *   │ String  (UTF-16, GC)        │ const char*  (UTF-8, malloc/free)   │
 *   │ jstring                     │ char*  terminado en '\0'            │
 *   │ memoria gestionada por GC   │ memoria que tú reservas y liberas   │
 *   └─────────────────────────────┴─────────────────────────────────────┘
 *
 * Contrato de recursos (LEE ESTO ANTES DE TOCAR NADA):
 *
 *   - GetStringUTFChars te PRESTA un puntero al texto del jstring.
 *     Siempre debes devolverlo con ReleaseStringUTFChars antes de salir,
 *     en cualquier camino, incluso de error.
 *
 *   - El buffer de salida (char*) es PROPIO: malloc/free son nuestra
 *     responsabilidad. La C de libcaesar no asigna memoria; el caller
 *     (nosotros) tiene que darle un buffer del tamaño exacto.
 *
 *   - El jstring de salida lo OWNA la JVM: NewStringUTF lo construye,
 *     el GC lo libera cuando Kotlin deja de referenciarlo.
 *
 * Toda la gestión de recursos vive en una sola función —
 * `apply_caesar_on_jvm_text`— para no duplicarla en cada entrypoint.
 */

#include <jni.h>
#include <stdlib.h>
#include <string.h>
#include "caesar.h"

/*
 * Firma común de las dos operaciones que expone libcaesar.h:
 *     void encrypt(const char* input, int shift, char* output);
 *     void decrypt(const char* input, int shift, char* output);
 *
 * Cualquier puntero a una función con esta forma puede pasarse a
 * `apply_caesar_on_jvm_text` como `caesar_operation`.
 */
typedef void (*CaesarOperation)(
    const char *plain_text,
    int alphabet_shift,
    char *output_buffer
);

/* +1 byte que reservamos en el buffer de salida para el '\0' terminador
 * que libcaesar escribe al final. Lo nombramos para no dejar literales
 * mágicos en el cálculo del tamaño. */
static const size_t NULL_TERMINATOR_SIZE = 1;

/*
 * Ejecuta una operación de libcaesar sobre un String venido de Kotlin
 * y devuelve el resultado como String para Kotlin.
 *
 * Esta es la ÚNICA función del fichero que toca recursos. Los dos
 * entrypoints JNI (`encryptNative`, `decryptNative`) son one-liners que
 * delegan aquí pasando `encrypt` o `decrypt`.
 *
 * Devuelve NULL si la JVM se queda sin memoria; en ese caso la JVM ya
 * tiene un OutOfMemoryError pendiente y Kotlin lo verá como excepción.
 */
static jstring apply_caesar_on_jvm_text(
    JNIEnv *jvm_environment,
    jstring jvm_input_text,
    jint alphabet_shift,
    CaesarOperation caesar_operation
) {
    const char *c_input_text = (*jvm_environment)->GetStringUTFChars(
        jvm_environment, jvm_input_text, NULL
    );
    if (c_input_text == NULL) {
        return NULL;
    }

    const size_t input_text_length  = strlen(c_input_text);
    const size_t output_buffer_size = input_text_length + NULL_TERMINATOR_SIZE;
    char *c_output_buffer = (char *)malloc(output_buffer_size);
    if (c_output_buffer == NULL) {
        (*jvm_environment)->ReleaseStringUTFChars(
            jvm_environment, jvm_input_text, c_input_text
        );
        return NULL;
    }

    caesar_operation(c_input_text, (int)alphabet_shift, c_output_buffer);

    (*jvm_environment)->ReleaseStringUTFChars(
        jvm_environment, jvm_input_text, c_input_text
    );

    jstring jvm_output_text = (*jvm_environment)->NewStringUTF(
        jvm_environment, c_output_buffer
    );
    free(c_output_buffer);
    return jvm_output_text;
}

/*
 * ─── Puntos de entrada JNI ─────────────────────────────────────────────
 *
 * Los nombres `Java_<paquete>_<clase>_<método>` son CONTRACTUALES con
 * la JVM. Cuando Kotlin invoca `Caesar.encryptNative(...)`, el linker
 * de la JVM busca un símbolo C con este nombre exacto en los .so
 * cargados. No renombres aquí sin actualizar también Caesar.kt — y
 * viceversa.
 */

JNIEXPORT jstring JNICALL
Java_com_nicovegasr_caesar_Caesar_encryptNative(
    JNIEnv *jvm_environment,
    jclass  caesar_class,
    jstring jvm_input_text,
    jint    alphabet_shift
) {
    (void)caesar_class;  /* método estático: el jclass no se usa. */
    return apply_caesar_on_jvm_text(
        jvm_environment, jvm_input_text, alphabet_shift, encrypt
    );
}

JNIEXPORT jstring JNICALL
Java_com_nicovegasr_caesar_Caesar_decryptNative(
    JNIEnv *jvm_environment,
    jclass  caesar_class,
    jstring jvm_input_text,
    jint    alphabet_shift
) {
    (void)caesar_class;
    return apply_caesar_on_jvm_text(
        jvm_environment, jvm_input_text, alphabet_shift, decrypt
    );
}
